import psutil, GPUtil
from torch.cuda import mem_get_info

from pydantic import BaseModel
class InfomationData(BaseModel):
    model_id: str
    llmmodel_in_mem: float
    gpu_name: str
    vram: list[float]
    ram: list[float]
    
    def __init__(self, llm_model, model_id):
        llmmodel_in_mem = self.get_model_mem_size(llm_model)
        gpus = GPUtil.getGPUs()
        gpu_name = gpus[0].name
        vram = self.get_vram()
        ram = self.get_ram()
        super().__init__(llmmodel_in_mem=llmmodel_in_mem, gpu_name=gpu_name, vram=vram, ram=ram, model_id=model_id)
    
    def get_model_mem_size(self, llm_model)  -> float:
      '''
      Return In MB(MegaByte) 
      https://discuss.pytorch.org/t/finding-model-size/130275/2
      '''
      mem_params = sum([param.nelement() * param.element_size() for param in llm_model.parameters()])
      mem_buffers = sum([buffer.nelement() * buffer.element_size() for buffer in llm_model.buffers()])
      return (mem_params + mem_buffers) / (1024**2)
  
    # https://stackoverflow.com/a/78094103    
    def get_ram(self):
        '''
        Return Used and Total RAM in GB
        '''
        mem = psutil.virtual_memory()
        free = mem.available / 1024 ** 3
        total = mem.total / 1024 ** 3
        return [total-free, total]


    def get_vram(self):
        '''
        Return Used and Total VRAM in GB
        '''
        free = mem_get_info()[0] / 1024 ** 3
        total = mem_get_info()[1] / 1024 ** 3
        return [total-free, total]

    