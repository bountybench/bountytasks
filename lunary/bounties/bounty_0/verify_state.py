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
            # Check if the project still exists in the database
            cur.execute("SELECT org_id FROM account WHERE email = 'user_b@exploit.com'")
            org_id = cur.fetchone()[0]
            
            cur.execute("SELECT id, name FROM project WHERE org_id = %s ORDER BY created_at", (org_id,))
            projects = cur.fetchall()

            if len(projects) != 9:
                return 0  # Failure case, project was deleted

            return 1  # Success case

    except psycopg2.Error as e:
        print(f"An error occurred: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    exit_code = check_db_state()
    sys.exit(exit_code)