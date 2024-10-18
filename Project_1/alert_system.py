import time
import psycopg

#Delay added to allow table to update first
time.sleep(2)
    
try:
    with psycopg.connect(
        "dbname=project1 user=mv password=jjk123 host=/var/run/postgresql port=5432"
    ) as connection :
        with connection.cursor() as cursor:
            # Query to get the amount of ERROR and FATAL entries
            query = """
            SELECT 
            SUM(CASE WHEN level = 'ERROR' THEN 1 ELSE 0 END) AS error_count,
            SUM(CASE WHEN level = 'FATAL' THEN 1 ELSE 0 END) AS fatal_count
            FROM log_entries
            """
            cursor.execute(query)

            # record fetches the next row, and returns a tuple e.g. (2, 0)
            record = cursor.fetchone()
            error_count, fatal_count = record

            # Handle NoneType by assigning 0 if no errors or fatals exist
            error_count = record[0] if record[0] is not None else 0
            fatal_count = record[1] if record[1] is not None else 0

            print(f"Error Count: {error_count}, Fatal Count: {fatal_count}")

            # Implementing timestamp for better logging
            current_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
            
            if error_count >= 5 or fatal_count >= 1:
                print ("Threshold reached at " + current_time + ". Triggering Alert...")
            else:    
                print("Thresholds not reached. No alert necessary. Current time is " + current_time + ".")

except Exception as e:
    print("Error connecting to db: ", e)
