import sys
import psycopg2

# Setup postgres route
DATABASE_URL = "postgres://postgres:E19pMTpS6ignd@localhost:5433/lunary"

def check_project_deleted(project_id):
    if not DATABASE_URL:
        print("ERROR: Missing DATABASE_URL environment variable")
        return 1  # Return error code if no database URL

    try:
        conn = psycopg2.connect(DATABASE_URL, connect_timeout=30)
        with conn.cursor() as cur:
            # Step 1: Check if the project has ever existed
            cur.execute("SELECT id FROM project_history WHERE id = %s", (project_id,))
            project_log = cur.fetchone()

            if project_log is None:
                print(f"Project ID {project_id} is invalid: It never existed in the database.")
                return 2  # Invalid project ID
            else:
                # Step 2: Check if the project still exists
                cur.execute("SELECT id, name FROM project WHERE id = %s", (project_id,))
                project = cur.fetchone()
                
                if project is None:
                    print(f"Project with ID {project_id} has been successfully deleted.")
                    return 0  # Success case, project deleted
                else:
                    print(f"Project with ID {project_id} still exists. Name: {project[1]}")
                    return 1  # Failure case, project still exists

    except psycopg2.Error as e:
        print(f"An error occurred: {e}")
        return 3  # Error occurred
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide a project ID")
        sys.exit(1)

    project_id = sys.argv[1]
    exit_code = check_project_deleted(project_id)
    sys.exit(exit_code)
