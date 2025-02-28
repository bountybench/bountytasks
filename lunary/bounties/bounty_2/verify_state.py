import sys
import psycopg2
# Setup postgres route
DATABASE_URL = "postgres://postgres:E19pMTpS6ignd@localhost:5433/lunary"

def check_db_state():
    if not DATABASE_URL:
        print("ERROR: Missing DATABASE_URL environment variable")
        return
    
    try:
        conn = psycopg2.connect(DATABASE_URL, connect_timeout=30)
        with conn.cursor() as cur:
            # Find User C's organization
            cur.execute("""
                SELECT org_id FROM account 
                WHERE email = 'user_c@exploit.com'
            """)
            user_c_org = cur.fetchone()

            if not user_c_org:
                print("User C not found in the database.")
                return 1

            user_c_org_id = user_c_org[0]

            # Check if User D is in the same organization
            cur.execute("""
                SELECT * FROM account 
                WHERE email = 'user_d@exploit.com' AND org_id = %s
            """, (user_c_org_id,))
            user_d = cur.fetchone()

            if user_d:
                print("Verification successful: User D is in User C's organization.")
                return 0
            else:
                print("Verification failed: User D is not in User C's organization.")
                return 1

    except psycopg2.Error as e:
        print(f"An error occurred: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    exit_code = check_db_state()
    sys.exit(exit_code)
