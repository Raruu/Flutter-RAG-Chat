import psutil, GPUtil
from torch.cuda import mem_get_info
from llm_model import Model
from pydantic import BaseModel


class InfomationData(BaseModel):
    llmmodel_id: str
    llmmodel_in_mem: float
    gpu_name: str
    vram: list[float]
    ram: list[float]
    len_context_knowledge: int
    list_context_knowledge: list[str]

    def __init__(self, llm_model: Model, llmmodel_id):
        llmmodel_in_mem = self.get_model_mem_size(llm_model.llm_model)
        gpus = GPUtil.getGPUs()
        gpu_name = gpus[0].name
        vram = self.get_vram()
        ram = self.get_ram()
        len_context_knowledge = len(llm_model.chat_room.context_knowledge)
        if len_context_knowledge > 0:
            list_context_knowledge = [
                llm_model.chat_room.context_knowledge[i]["filename"]
                for i in range(len_context_knowledge)
            ]
        else:
            list_context_knowledge = []
        super().__init__(
            llmmodel_in_mem=llmmodel_in_mem,
            gpu_name=gpu_name,
            vram=vram,
            ram=ram,
            llmmodel_id=llmmodel_id,
            len_context_knowledge=len_context_knowledge,
            list_context_knowledge=list_context_knowledge,
        )

    def get_model_mem_size(self, llm_model) -> float:
        """
        Return In MB(MegaByte)
        https://discuss.pytorch.org/t/finding-model-size/130275/2
        """
        mem_params = sum(
            [
                param.nelement() * param.element_size()
                for param in llm_model.parameters()
            ]
        )
        mem_buffers = sum(
            [
                buffer.nelement() * buffer.element_size()
                for buffer in llm_model.buffers()
            ]
        )
        return (mem_params + mem_buffers) / (1024**2)

    # https://stackoverflow.com/a/78094103
    def get_ram(self):
        """
        Return Used and Total RAM in GB
        """
        mem = psutil.virtual_memory()
        free = mem.available / 1024**3
        total = mem.total / 1024**3
        return [total - free, total]

    def get_vram(self):
        """
        Return Used and Total VRAM in GB
        """
        free = mem_get_info()[0] / 1024**3
        total = mem_get_info()[1] / 1024**3
        return [total - free, total]
