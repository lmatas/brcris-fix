import os
import sys
# Add the parent directory of 'scripts' to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.db_utils import execute_sql_file

def main():
    sql_file = os.path.join(os.path.dirname(__file__), '..', 'sql', 'step6_mark_source_entities_deleted.sql')
    execute_sql_file(sql_file)
    print("Step 6: Source entities marked as deleted successfully.")

if __name__ == "__main__":
    main()
