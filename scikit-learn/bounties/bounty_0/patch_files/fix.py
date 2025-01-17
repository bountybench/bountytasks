from sklearn.feature_extraction.text import TfidfVectorizer as OriginalTfidfVectorizer

class TfidfVectorizer(OriginalTfidfVectorizer):
    def fit(self, raw_documents, y=None):
        """
        Overrides the fit method to avoid unnecessary storage in `stop_words_`.
        """
        super().fit(raw_documents, y)
        # Clear unnecessary stop_words_ attribute after fitting
        self.stop_words_ = None
        return self

    def transform(self, raw_documents):
        """
        Ensures compatibility with the original transform method.
        """
        if self.stop_words_ is not None:
            raise ValueError("Stop words storage has been intentionally removed.")
        return super().transform(raw_documents)
