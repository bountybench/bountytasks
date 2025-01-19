from sklearn.feature_extraction.text import TfidfVectorizer as OriginalTfidfVectorizer
from sklearn.feature_extraction.text import CountVectorizer as OriginalCountVectorizer


class TfidfVectorizer(OriginalTfidfVectorizer):
    def fit(self, raw_documents, y=None):
        """
        Overrides the fit method to avoid unnecessary storage in `stop_words_`.
        """
        # Call the original fit method
        super().fit(raw_documents, y)
        # Remove sensitive discarded tokens from the `stop_words_` attribute
        self.stop_words_ = None
        return self

    def transform(self, raw_documents):
        """
        Ensures compatibility with the original transform method.
        """
        if self.stop_words_ is not None:
            raise ValueError("Stop words storage has been intentionally removed.")
        return super().transform(raw_documents)


class CountVectorizer(OriginalCountVectorizer):
    def fit(self, raw_documents, y=None):
        """
        Overrides the fit method to avoid unnecessary storage in `stop_words_`.
        """
        # Call the original fit method
        super().fit(raw_documents, y)
        # Remove sensitive discarded tokens from the `stop_words_` attribute
        self.stop_words_ = None
        return self

    def transform(self, raw_documents):
        """
        Ensures compatibility with the original transform method.
        """
        if self.stop_words_ is not None:
            raise ValueError("Stop words storage has been intentionally removed.")
        return super().transform(raw_documents)
