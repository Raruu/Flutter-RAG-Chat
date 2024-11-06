import gc, pytesseract, io, os, torch, fitz
from spacy.lang.en import English
from helper import *
from fastapi import UploadFile
from sentence_transformers import SentenceTransformer, util
from PIL import Image

from data_models.generate_text_model import PostGenerateText, ReturnGeneratedText

if os.name == "nt":
    pytesseract.pytesseract.tesseract_cmd = (
        "C:\\Program Files\\Tesseract-OCR\\tesseract.exe"
    )


class ChatRoom:
    def __init__(self, device: str):
        self.nlp = English()
        self.nlp.add_pipe("sentencizer")
        self.device = device
        self.embedding_model: SentenceTransformer = None
        self.id = ""
        self.chat_context_embedding = None
        self.context_knowledges = []

    def set_embedding_model(self, embedding_model: SentenceTransformer):
        if self.embedding_model is not None:
            del self.embedding_model
            gc.collect()
            torch.cuda.empty_cache()
        self.embedding_model = embedding_model

    def delete_context_knowledge(self, filename: str):
        if filename == "":
            for contexts in self.context_knowledges:
                self.context_knowledges.remove(contexts)
                del contexts
            self.context_knowledges = []
            return True
        else:
            for contexts in self.context_knowledges:
                if contexts["filename"] == filename:
                    self.context_knowledges.remove(contexts)
                    del contexts
                    return True
        return False

    async def add_context_knowledge(self, data: UploadFile):
        new_dict = {"filename": data.filename}
        pages_and_texts = []
        if data.filename.endswith(".pdf"):
            contents = await data.read()
            doc = fitz.open(stream=contents, filetype="pdf")
            for page_number, page in enumerate(doc):
                text = page.get_text().replace("\n", " ").strip()

                for img_index, img in enumerate(page.get_images(full=True)):
                    xref = img[0]
                    base_image = doc.extract_image(xref)
                    image_bytes = base_image["image"]

                    image = Image.open(io.BytesIO(image_bytes))
                    image_text = pytesseract.image_to_string(image)
                    text += " " + image_text.strip()

                self.add_context_knowledge_process_text(
                    pages_and_texts, text, page_number
                )

        elif data.filename.endswith((".png", ".jpg", ".jpeg", ".webp")):
            image = Image.open(io.BytesIO(await data.read()))
            text = pytesseract.image_to_string(image).strip()
            self.add_context_knowledge_process_text(pages_and_texts, text, 1)

        new_dict["pages_and_texts"] = pages_and_texts
        self.context_knowledges.append(new_dict)

    def add_context_knowledge_process_text(
        self, pages_and_texts: dict, text: str, page_number: int
    ):
        if not text:
            return
        sentences = [str(sentence) for sentence in list(self.nlp(text).sents)]
        sentences_chunks = split_list(sentences, 10)
       
        for sentences_chunk in sentences_chunks:
            joined_sentence_chunk = join_sentences_chunk_to_paragraph(sentences_chunk)
        embeddings = self.embedding_model.encode(
            joined_sentence_chunk, convert_to_tensor=True
        ).to(self.device)
        pages_and_texts.append(
            {
                "page_number": page_number + 1,
                "text": text,
                "sentences_chunks": sentences_chunks,
                "joined_sentence_chunk": joined_sentence_chunk,
                "embeddings": embeddings,
            }
        )
        return pages_and_texts

    def get_context_knowledge(self):
        top_products_avg = torch.zeros(1).to(self.device)
        len_top_products_avg = 0
        possible_contexts = []
        for knowledge in self.context_knowledges:
            pages_and_texts = knowledge["pages_and_texts"]
            dot_scores = util.dot_score(
                a=self.query_embedding,
                b=torch.stack(
                    [
                        pages_and_texts[i]["embeddings"]
                        for i in range(len(pages_and_texts))
                    ]
                ),
            )[0]
            k = clamp(len(dot_scores), 0, 5)
            top_products = torch.topk(dot_scores, k=k)
            for i in top_products[0]:
                top_products_avg += i
            len_top_products_avg += k

            for score, idx in zip(top_products[0], top_products[1]):
                possible_contexts.append(
                    {
                        "context": pages_and_texts[idx]["joined_sentence_chunk"],
                        "score": score.item(),
                        "page_number": pages_and_texts[idx]["page_number"],
                        "filename": knowledge["filename"],
                    }
                )

        return sorted(possible_contexts, key=lambda x: x["score"], reverse=True)

    def join_context_knowledge(self, contexts: list[dict]) -> str:
        knowledge_list = []
        for item in contexts:
            knowledge_list.append(item["context"])
        return "\n".join(knowledge_list)

    def get_context_chat_history(self, chat_history: list[str]):
        if not chat_history:
            return
        self.joined_sentence_chunks = []
        for text_chat in chat_history:
            sentences = [str(sentence) for sentence in list(self.nlp(text_chat).sents)]
            sentences_chunks = split_list(sentences, 7)
            for sentences_chunk in sentences_chunks:
                joined_sentence_chunk = join_sentences_chunk_to_paragraph(
                    sentences_chunk
                )
                self.joined_sentence_chunks.append(joined_sentence_chunk)
        self.chat_context_embedding = self.embedding_model.encode(
            self.joined_sentence_chunks, convert_to_tensor=True
        ).to(self.device)

        dot_scores = util.dot_score(
            a=self.query_embedding, b=self.chat_context_embedding
        )[0]
        k = clamp(len(dot_scores), 0, 5)
        top_products = torch.topk(dot_scores, k=k)
        # print(f"[chat_room/get_context_chat_history] top_products: {top_products}")

        return [self.joined_sentence_chunks[top_products[1][i]] for i in range(k)]

    def join_chat_history(self, chat_history: list[str]):
        return "\n".join(chat_history)

    def embedd_query(self, query: str):
        try:
            del self.query_embedding
            gc.collect()
            torch.cuda.empty_cache()
        except:
            pass
        self.query_embedding = self.embedding_model.encode(
            query, convert_to_tensor=True
        ).to(self.device)

    def build_context(
        self, data: PostGenerateText, return_generate_text: ReturnGeneratedText
    ):
        self.embedd_query(data.query)
        return_generate_text.context1 = self.get_context_knowledge()
        return_generate_text.context2 = self.get_context_chat_history(data.context2)
        return return_generate_text.context1

    def build_prompt(
        self, data: PostGenerateText, return_generate_text: ReturnGeneratedText
    ):
        query = data.query
        if self.embedding_model is not None:
            self.embedd_query(query)
        prompt = data.preprompt if data.preprompt is not None else ""

        if data.context1:
            return_generate_text.context1 = data.context1
            get_knowledge_context = self.join_context_knowledge(data.context1)
            if "{context_knowledge}" in prompt:
                prompt = prompt.replace("{context_knowledge}", get_knowledge_context)
            else:
                prompt = prompt + f"Context1:\n {get_knowledge_context}"

        if data.context2:
            get_chat_context = self.join_chat_history(data.context2)
            return_generate_text.context2 = get_chat_context
            print(f"[chat_room/build_prompt] chat_history_context : {get_chat_context}")
            if "{chat_history}" in prompt:
                prompt = prompt.replace("{chat_history}", get_chat_context)
            else:
                prompt = prompt + f"Context2:\n {get_chat_context}"

        if "{query}" in prompt:
            prompt = prompt.replace("{query}", query)
        else:
            prompt = prompt + f"\nUser Query: {query}"
        return prompt
