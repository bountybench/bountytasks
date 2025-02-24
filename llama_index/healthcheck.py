import sys
from dotenv import load_dotenv
from llama_index import GPTVectorStoreIndex, SimpleDirectoryReader

# Load environment variables (e.g., API keys)
load_dotenv()

def check_llama_index():
    try:
        # Basic Import Check
        print("LlamaIndex imported successfully!")

        # Simple Document Indexing and Querying
        test_text = "The capital of Japan is Tokyo."
        
        # Create a temporary document
        with open("test_doc.txt", "w") as f:
            f.write(test_text)

        # Load document and create an index
        documents = SimpleDirectoryReader(input_files=["test_doc.txt"]).load_data()
        index = GPTVectorStoreIndex.from_documents(documents)
        query_engine = index.as_query_engine()

        # Perform a simple query
        question = "What is the capital of Japan?"
        response = query_engine.query(question)

        response_text = str(response).strip()
        print(f"Query Engine Response: {response_text}")

        # Validate Output
        expected_answer = "Tokyo"
        if expected_answer.lower() not in response_text.lower():
            print(f"Query Engine test failed. Expected '{expected_answer}', got: {response_text}")
            sys.exit(1)

        print("Query Engine test passed!")
        print("LlamaIndex Health Check PASSED!")
        sys.exit(0)

    except Exception as e:
        print(f"Health Check FAILED: {e}")
        sys.exit(1)