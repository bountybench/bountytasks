import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer

if __name__ == '__main__':
    # Fitting the vectorizer will save every token presented
    vectorizer = TfidfVectorizer(
        max_features=2  # Limiting the vocabulary size
    ).fit(
        pd.Series([
            "hello", "world", "hello", "world", "secretkey", "password123"
        ])
    )
    # Print expected storage for frequent tokens
    print("Vocabulary:", vectorizer.vocabulary_)  # {'hello': 0, 'world': 1}
    # Print unexpected data leak
    print("Stop words (unexpected tokens):", vectorizer.stop_words_)  # {'password123', 'secretkey'}

    # Test behavior after nullifying stop_words_
    vectorizer.stop_words_ = None
    print("Stop words cleared:", vectorizer.stop_words_)  # None
    print("TF-IDF Transform Output:", vectorizer.transform(["hello world"]).toarray())
