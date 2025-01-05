print('Victim script started')

import torch
import torch.distributed as dist
import mmdet.utils

print('starting victim')
# Initialize as receiver (rank=1)
dist.init_process_group(backend="gloo", rank=1, world_size=2, init_method="tcp://0.0.0.0:29500")
print("Victim listening on tcp://0.0.0.0:29500")
mmdet.utils.all_reduce_dict({})