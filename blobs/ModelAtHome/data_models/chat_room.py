from spacy.lang.en import English
from helper import *
from fastapi import UploadFile
import re, torch, fitz
from sentence_transformers import SentenceTransformer, util

from data_models.generate_text_model import ReturnGeneratedText


class ChatRoom:
    def __init__(self, device: str, embedding_model: SentenceTransformer):
        self.nlp = English()
        self.nlp.add_pipe("sentencizer")
        self.device = device
        self.embedding_model = embedding_model
        self.id = ""
        self.use_chat_history = False
        self.chat_history = []
        self.preprompt = ""
        self.use_preprompt = False
        self.chat_context_embedding = None
        self.context_knowledge = []

    def delete_context_knowledge(self, filename: str):
        if filename == "":
            for contexts in self.context_knowledge:
                self.context_knowledge.remove(contexts)
                del contexts
            self.context_knowledge = []
            return True
        else:
            for contexts in self.context_knowledge:
                if contexts["filename"] == filename:
                    self.context_knowledge.remove(contexts)
                    del contexts
                    return True
        return False

    async def add_context_knowledge(self, data: UploadFile):
        new_dict = {"filename": data.filename}
        contents = await data.read()
        doc = fitz.open(stream=contents, filetype="pdf")
        pages_and_texts = []
        for page_number, page in enumerate(doc):
            text = page.get_text().replace("\n", " ").strip()
            sentences = [str(sentence) for sentence in list(self.nlp(text).sents)]
            sentences_chunks = split_list(sentences, 10)
            for sentences_chunk in sentences_chunks:
                joined_sentence_chunk = join_sentences_chunk_to_paragraph(
                    sentences_chunk
                )
            embeddings = self.embedding_model.encode(
                joined_sentence_chunk, convert_to_tensor=True
            ).to(self.device)
            pages_and_texts.append(
                {
                    "page_number": page_number,
                    "text": text,
                    "sentences_chunks": sentences_chunks,
                    "joined_sentence_chunk": joined_sentence_chunk,
                    "embeddings": embeddings,
                }
            )
        new_dict["pages_and_texts"] = pages_and_texts
        self.context_knowledge.append(new_dict)

    def get_context_knowledge(self):
        top_products_avg = torch.zeros(1).to(self.device)
        len_top_products_avg = 0
        possible_contexts = []
        for knowledges in self.context_knowledge:
            for item in knowledges["pages_and_texts"]:
                dot_scores = util.dot_score(
                    a=self.query_embedding, b=item["embeddings"]
                )[0]
                k = clamp(len(dot_scores), 0, 5)
                top_products = torch.topk(dot_scores, k=k)
                for i in top_products[0]:
                    top_products_avg += i
                len_top_products_avg += k
                possible_contexts.append(
                    {
                        "context": [
                            item["sentences_chunks"][top_products[1][i]]
                            for i in range(k)
                        ],
                        "top_products": top_products,
                        "page_number": item["page_number"],
                        "filename": knowledges["filename"],
                    }
                )
        top_products_avg = top_products_avg / len_top_products_avg
        higher_quality_context = []
        for item in possible_contexts:
            high_context = []
            for i in range(len(item["context"])):
                if i > 3:
                    break
                if item["top_products"][0][i] > top_products_avg:
                    high_context.append(item["context"][i])
            if len(high_context) > 0:
                higher_quality_context.append(
                    {
                        "filename": item["filename"],
                        "page_number": item["page_number"],
                        "score": item["top_products"][0][i].item(),
                        "context": high_context,
                    }
                )

        return higher_quality_context

    def update_chat_history(self, user_input, response):
        self.chat_history.append(f"User: {user_input}")
        self.chat_history.append(f"Model: {response}")

    def update_chat_context(self):
        self.joined_sentence_chunks = []
        for text_chat in self.chat_history:
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

    def get_context_chat_history(self):
        dot_scores = util.dot_score(
            a=self.query_embedding, b=self.chat_context_embedding
        )[0]
        k = clamp(len(dot_scores), 0, 3)
        top_products = torch.topk(dot_scores, k=k)
        print(f"[chat_room/get_context_chat_history] top_products: {top_products}")

        return [self.joined_sentence_chunks[top_products[1][i]] for i in range(k)]

    def build_prompt(self, query: str, return_generate_text: ReturnGeneratedText):
        self.query_embedding = self.embedding_model.encode(
            query, convert_to_tensor=True
        ).to(self.device)
        prompt = ""
        if self.use_preprompt:
            prompt = self.preprompt

        if len(self.context_knowledge) > 0:
            get_knowledge_context = self.get_context_knowledge()
            print(
                f"[chat_room/build_prompt] get_context_knowledge : {get_knowledge_context}"
            )

            return_generate_text.context1 = get_knowledge_context
            knowledge_list = []
            for item in get_knowledge_context:
                for contexts in item["context"]:
                    for context in contexts:
                        knowledge_list.append(context)
            get_knowledge_context = "\n".join(knowledge_list)
            print(
                f"[chat_room/build_prompt] context_knowledge : {get_knowledge_context}"
            )
            if "{context_knowledge}" in prompt:
                prompt = prompt.replace("{context_knowledge}", get_knowledge_context)
            else:
                prompt = prompt + f"Context1:\n {get_knowledge_context}"

        if self.use_chat_history and len(self.chat_history) > 0:
            self.update_chat_context()
            get_chat_context = "\n".join(self.get_context_chat_history())
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
