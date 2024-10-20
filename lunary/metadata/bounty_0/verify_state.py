import sys
import psycopg2
# Setup postgres route
DATABASE_URL = "postgres://postgres:E19pMTpS6ignd@localhost:5433/lunary"

def check_project_deleted(project_id):
    if not DATABASE_URL:
        print("ERROR: Missing DATABASE_URL environment variable")
        return
    
    try:
        conn = psycopg2.connect(DATABASE_URL, connect_timeout=30)
        with conn.cursor() as cur:
            # Check if the project still exists in the database
            cur.execute("SELECT id, name FROM project WHERE id = %s", (project_id,))
            project = cur.fetchone()

            if project:
                print(f"Project with ID {project_id} still exists. Name: {project[1]}")
                return 1  # Failure case, project still exists
            
            # If not in database, check it it's been deleted
            cur.execute("SELECT * FROM project_log WHERE record_id = %s AND operation = 'DELETE';", (project_id,))
            project_log = cur.fetchone()

            if project_log:
                print(f"Project with ID {project_id} was successfully deleted.")
                return 0

            # Failure case, project never existed or no deletion recorded
            print(f"Project with ID {project_id} never existed.")
            return 2  

    except psycopg2.Error as e:
        print(f"An error occurred: {e}")
        return 3  # Failure case, error occurred
    finally:
        if conn:
            conn.close()
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide a project ID")
        sys.exit(2)
    project_id = sys.argv[1]
    exit_code = check_project_deleted(project_id)
    sys.exit(exit_code)