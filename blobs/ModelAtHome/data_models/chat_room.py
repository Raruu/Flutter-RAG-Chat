from spacy.lang.en import English
from helper import split_list, clamp
import re, torch
from sentence_transformers import SentenceTransformer, util


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

    def update_chat_history(self, user_input, response):
        self.chat_history.append(f"User: {user_input}")
        self.chat_history.append(f"Model: {response}")

    def update_chat_context(self):
        self.joined_sentence_chunks = []
        for text_chat in self.chat_history:
            sentences = [str(sentence) for sentence in list(self.nlp(text_chat).sents)]
            sentences_chunks = split_list(sentences, 7)
            for sentences_chunk in sentences_chunks:
                joined_sentence_chunk = (
                    "".join(sentences_chunk).replace("  ", " ").strip()
                )
                joined_sentence_chunk = re.sub(
                    r"\.([A-Z])", r". \1", joined_sentence_chunk
                )
                self.joined_sentence_chunks.append(joined_sentence_chunk)
        self.chat_context_embedding = self.embedding_model.encode(
            self.joined_sentence_chunks, convert_to_tensor=True
        ).to(self.device)

    def get_context_chat_history(self, query: str):
        query_embedding = self.embedding_model.encode(query, convert_to_tensor=True).to(
            self.device
        )
        dot_scores = util.dot_score(a=query_embedding, b=self.chat_context_embedding)[0]
        k = clamp(len(dot_scores), 0, 3)
        top_products = torch.topk(dot_scores, k=k)
        # print(f"[get_context_chat_history] top_products: {top_products}")
        # print(f"chat_history len: {len(self.chat_history)}")
        # print(top_products[1][i] for i in range(k))

        return [self.joined_sentence_chunks[top_products[1][i]] for i in range(k)]

    def build_prompt(self, query: str):
        prompt = ""
        if self.use_preprompt:
            prompt = self.preprompt
        if self.use_chat_history and len(self.chat_history) > 0:
            self.update_chat_context()
            get_chat_context = "\n".join(self.get_context_chat_history(query))
            print(f"[build_prompt] chat_history_context : {get_chat_context}")
            if "{chat_history}" in prompt:
                prompt = prompt.replace("{chat_history}", get_chat_context)
            else:
                prompt = prompt + f"Context:\n {get_chat_context}"

        if "{query}" in prompt:
            prompt = prompt.replace("{query}", query)
        else:
            prompt = prompt + f"\nUser Query: {query}"
        return prompt
