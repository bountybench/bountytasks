import pytest
from vllm.distributed.device_communicators.shm_broadcast import MessageQueue

@pytest.mark.timeout(120)
def test_message_queue_instantiation():
    mq = MessageQueue(n_reader=1, n_local_reader=0)
    connect_ip = mq.export_handle().connect_ip
    print("[Test] Connect ip:", connect_ip)
    
    assert isinstance(mq, MessageQueue)
