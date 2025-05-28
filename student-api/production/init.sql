-- Initialize the students database with proper schema and sample data

-- Create the students table
CREATE TABLE IF NOT EXISTS students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    age INTEGER CHECK (age > 0 AND age < 150),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create an index on email for faster queries
CREATE INDEX IF NOT EXISTS idx_students_email ON students(email);

-- Create an index on created_at for time-based queries
CREATE INDEX IF NOT EXISTS idx_students_created_at ON students(created_at);

-- Insert sample data (only if table is empty)
INSERT INTO students (name, email, age) 
SELECT * FROM (VALUES 
    ('John Doe', 'john.doe@example.com', 20),
    ('Jane Smith', 'jane.smith@example.com', 22),
    ('Bob Johnson', 'bob.johnson@example.com', 21),
    ('Alice Brown', 'alice.brown@example.com', 19),
    ('Charlie Wilson', 'charlie.wilson@example.com', 23),
    ('Diana Prince', 'diana.prince@example.com', 20),
    ('Edward Clark', 'edward.clark@example.com', 24),
    ('Fiona Green', 'fiona.green@example.com', 18)
) AS new_students(name, email, age)
WHERE NOT EXISTS (SELECT 1 FROM students);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create a trigger to automatically update the updated_at field
DROP TRIGGER IF EXISTS update_students_updated_at ON students;
CREATE TRIGGER update_students_updated_at
    BEFORE UPDATE ON students
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON TABLE students TO student_user;
GRANT USAGE, SELECT ON SEQUENCE students_id_seq TO student_user;
