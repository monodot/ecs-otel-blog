require('dotenv').config();
const express = require('express');
const {Pool} = require('pg');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'holiday_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'password',
});

const initDatabase = async () => {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS holiday_packages
            (
                id
                SERIAL
                PRIMARY
                KEY,
                destination
                VARCHAR
            (
                255
            ) NOT NULL,
                price DECIMAL
            (
                10,
                2
            ) NOT NULL,
                duration_days INTEGER NOT NULL,
                availability INTEGER NOT NULL,
                description TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
        `);
        console.log('Database table initialized');

        // Check if we need to insert sample data (only for development)
        if (process.env.NODE_ENV !== 'production') {
            const result = await pool.query('SELECT COUNT(*) FROM holiday_packages');
            const count = parseInt(result.rows[0].count);

            if (count === 0) {
                await pool.query(`
                    INSERT INTO holiday_packages (destination, price, duration_days, availability, description)
                    VALUES ('Bali, Indonesia', 1299.99, 7, 15,
                            'Tropical paradise with beautiful beaches and rich culture'),
                           ('Paris, France', 899.50, 5, 8,
                            'City of love with iconic landmarks and world-class cuisine'),
                           ('Tokyo, Japan', 1599.00, 10, 12, 'Modern metropolis blending tradition and innovation'),
                           ('Santorini, Greece', 1150.75, 6, 10,
                            'Stunning sunsets and white-washed buildings on volcanic cliffs'),
                           ('Rhyl, Wales', 499.99, 3, 20, 'Charming coastal town with sandy beaches and family-friendly attractions'),
                           ('Blackpool, England', 59.99, 2, 30, 'Famous seaside resort with amusement parks and vibrant nightlife'),
                           ('Edinburgh, Scotland', 349.99, 4, 25, 'Historic city with stunning architecture and rich heritage'),
                           ('Dublin, Ireland', 399.99, 3, 18, 'Lively capital known for its friendly locals and vibrant culture'),
                           ('Amsterdam, Netherlands', 749.99, 5, 15, 'Picturesque canals and world-renowned museums'),
                           ('Barcelona, Spain', 899.00, 6, 20,
                            'Architectural wonders and beautiful Mediterranean beaches') ON CONFLICT DO NOTHING;

                `);
                console.log('Sample data inserted');
            }
        }
    } catch (err) {
        console.error('Error initializing database:', err);
    }
};

// GET /packages - Get all holiday packages
app.get('/packages', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM holiday_packages ORDER BY id');
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching packages:', err);
        res.status(500).json({error: 'Internal server error'});
    }
});

// GET /packages/:id - Get a specific holiday package
app.get('/packages/:id', async (req, res) => {
    try {
        const {id} = req.params;
        const result = await pool.query('SELECT * FROM holiday_packages WHERE id = $1', [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({error: 'Package not found'});
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Error fetching package:', err);
        res.status(500).json({error: 'Internal server error'});
    }
});

// POST /packages - Create a new holiday package
app.post('/packages', async (req, res) => {
    try {
        const {destination, price, duration_days, availability, description} = req.body;

        // Basic validation
        if (!destination || !price || !duration_days || availability === undefined) {
            return res.status(400).json({
                error: 'Missing required fields: destination, price, duration_days, availability'
            });
        }

        const result = await pool.query(
            `INSERT INTO holiday_packages (destination, price, duration_days, availability, description)
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [destination, price, duration_days, availability, description || null]
        );

        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error('Error creating package:', err);
        res.status(500).json({error: 'Internal server error'});
    }
});

// PUT /packages/:id - Update a holiday package
app.put('/packages/:id', async (req, res) => {
    try {
        const {id} = req.params;
        const {destination, price, duration_days, availability, description} = req.body;

        // Basic validation
        if (!destination || !price || !duration_days || availability === undefined) {
            return res.status(400).json({
                error: 'Missing required fields: destination, price, duration_days, availability'
            });
        }

        const result = await pool.query(
            `UPDATE holiday_packages
             SET destination = $1,
                 price = $2,
                 duration_days = $3,
                 availability = $4,
                 description   = $5,
                 updated_at    = CURRENT_TIMESTAMP
             WHERE id = $6 RETURNING *`,
            [destination, price, duration_days, availability, description || null, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({error: 'Package not found'});
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Error updating package:', err);
        res.status(500).json({error: 'Internal server error'});
    }
});

// DELETE /packages/:id - Delete a holiday package
app.delete('/packages/:id', async (req, res) => {
    try {
        const {id} = req.params;
        const result = await pool.query('DELETE FROM holiday_packages WHERE id = $1 RETURNING *', [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({error: 'Package not found'});
        }

        res.json({message: 'Package deleted successfully', package: result.rows[0]});
    } catch (err) {
        console.error('Error deleting package:', err);
        res.status(500).json({error: 'Internal server error'});
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({status: 'OK', timestamp: new Date().toISOString()});
});

const startServer = async () => {
    await initDatabase();
    app.listen(port, () => {
        console.log(`Holiday packages API running on port ${port}`);
        console.log(`Health check: http://localhost:${port}/health`);
        console.log(`API endpoints:`);
        console.log(`  GET    /packages     - Get all packages`);
        console.log(`  GET    /packages/:id - Get package by ID`);
        console.log(`  POST   /packages     - Create new package`);
        console.log(`  PUT    /packages/:id - Update package`);
        console.log(`  DELETE /packages/:id - Delete package`);
    });
};

startServer().catch(console.error);
