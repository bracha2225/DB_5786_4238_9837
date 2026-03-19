import csv
import random
from datetime import datetime, timedelta

def generate_patient_data(num_rows=20000):
    # Data pools for realistic generation
    first_names = ["James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael", "Linda", "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Charles", "Karen"]
    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin"]
    genders = ["Male", "Female", "Other", "Prefer not to say"]
    streets = ["Maple St", "Oak Ave", "Washington Blvd", "Lakeview Dr", "Parkway Rd", "Cedar Ln", "Main St", "8th St", "River Rd"]
    cities = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego"]

    filename = "patients.csv"

    with open(filename, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerow(["first_name", "last_name", "date_of_birth", "gender", "phone", "email", "address"])

        for i in range(1, num_rows + 1):
            first = random.choice(first_names)
            last = random.choice(last_names)
            
            # 1. Date of Birth (Past only: between 1 and 90 years ago)
            days_ago = random.randint(365, 32850)
            dob = (datetime.now() - timedelta(days=days_ago)).date()

            # 2. Gender (Respects allowed values)
            gender = random.choice(genders)

            # 3. Phone (Standard format)
            phone = f"{random.randint(200, 999)}-{random.randint(100, 999)}-{random.randint(1000, 9999)}"

            # 4. Email (Guaranteed unique by appending the loop index)
            email = f"{first.lower()}.{last.lower()}.{i}@hospital-mail.com"

            # 5. Address
            address = f"{random.randint(1, 9999)} {random.choice(streets)}, {random.choice(cities)}"

            # Write row (EXCLUDING patient_id as it is auto-generated)
            writer.writerow([first, last, dob, gender, phone, email, address])

    print(f"Success! {filename} created with {num_rows} rows.")

generate_patient_data(20000)
print("DONE")