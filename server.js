const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Accept']
}));

const PORT = process.env.PORT || 3001;

// Database connection
const connection = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "automated_judging_system"
});

connection.connect((err) => {
    if (err) {
        console.error('Database connection failed:', err);
        return;
    }
    console.log('Connected to MySQL database: automated_judging_system');
});

// Error handler middleware
const handleError = (res, err, message = "Server error") => {
    console.error('Database Error:', err);
    res.status(500).json({ msg: message, error: err.message });
};

// ============= EVENT TYPES ENDPOINTS =============
app.get("/api/event-types", (req, res) => {
    console.log('GET /api/event-types requested');
    connection.query("SELECT * FROM event_types ORDER BY name", (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch event types');
        console.log(`Returned ${rows.length} event types`);
        res.json(rows);
    });
});

app.post('/api/event-types', (req, res) => {
    const { name, description, max_participants } = req.body;
    console.log('POST /api/event-types:', req.body);
    
    if (!name || name.trim() === '') {
        return res.status(400).json({ msg: 'Name is required' });
    }
    
    connection.query(
        `INSERT INTO event_types (name, description, max_participants, created_at) VALUES (?, ?, ?, NOW())`, 
        [name.trim(), description?.trim() || null, max_participants || 50],
        (err, result) => {
            if (err) {
                if (err.code === 'ER_DUP_ENTRY') {
                    return res.status(400).json({ msg: 'Event type name already exists' });
                }
                return handleError(res, err, 'Failed to create event type');
            }
            console.log(`Created event type: ${name} with ID: ${result.insertId}`);
            res.json({ msg: `Successfully created event type: ${name}`, id: result.insertId });
        }
    );
});

app.put('/api/event-types/:id', (req, res) => {
    const { id } = req.params;
    const { name, description, max_participants } = req.body;
    console.log(`PUT /api/event-types/${id}:`, req.body);
    
    if (!name || name.trim() === '') {
        return res.status(400).json({ msg: 'Name is required' });
    }
    
    connection.query(
        `UPDATE event_types SET name = ?, description = ?, max_participants = ?, updated_at = NOW() WHERE id = ?`,
        [name.trim(), description?.trim() || null, max_participants || 50, id],
        (err, result) => {
            if (err) {
                if (err.code === 'ER_DUP_ENTRY') {
                    return res.status(400).json({ msg: 'Event type name already exists' });
                }
                return handleError(res, err, 'Failed to update event type');
            }
            if (result.affectedRows === 0) {
                return res.status(404).json({ msg: 'Event type not found' });
            }
            console.log(`Updated event type ID: ${id}`);
            res.json({ msg: `Successfully updated event type: ${name}` });
        }
    );
});

app.delete('/api/event-types/:id', (req, res) => {
    const { id } = req.params;
    console.log(`DELETE /api/event-types/${id}`);
    
    connection.query(`DELETE FROM event_types WHERE id = ?`, [id], (err, result) => {
        if (err) return handleError(res, err, 'Failed to delete event type');
        if (result.affectedRows === 0) {
            return res.status(404).json({ msg: 'Event type not found' });
        }
        console.log(`Deleted event type ID: ${id}`);
        res.json({ msg: 'Event type deleted successfully' });
    });
});

// ============= COMPETITIONS ENDPOINTS =============
app.get("/api/competitions", (req, res) => {
    console.log('GET /api/competitions requested');
    connection.query(`
        SELECT c.*, et.name as event_type_name 
        FROM competitions c 
        LEFT JOIN event_types et ON c.event_type_id = et.id 
        ORDER BY c.created_at DESC
    `, (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch competitions');
        
        // Map the result to match expected format
        const competitions = rows.map(row => ({
            id: row.id,
            name: row.name,
            description: row.description,
            date: row.date,
            event_type: row.event_type_name,
            status: row.status,
            created_at: row.created_at,
            updated_at: row.updated_at
        }));
        
        console.log(`Returned ${competitions.length} competitions`);
        res.json(competitions);
    });
});

app.post('/api/competitions', (req, res) => {
    const { name, description, date, event_type } = req.body;
    console.log('POST /api/competitions:', req.body);
    
    if (!name || name.trim() === '' || !description || description.trim() === '') {
        return res.status(400).json({ msg: 'Name and description are required' });
    }
    
    // First, find the event_type_id
    if (event_type) {
        connection.query(
            `SELECT id FROM event_types WHERE name = ?`,
            [event_type],
            (err, eventTypeResult) => {
                if (err) return handleError(res, err, 'Failed to find event type');
                
                const eventTypeId = eventTypeResult.length > 0 ? eventTypeResult[0].id : null;
                
                connection.query(
                    `INSERT INTO competitions (name, description, date, event_type_id, status, created_at) VALUES (?, ?, ?, ?, 'active', NOW())`, 
                    [name.trim(), description.trim(), date || null, eventTypeId],
                    (err, result) => {
                        if (err) return handleError(res, err, 'Failed to create competition');
                        console.log(`Created competition: ${name} with ID: ${result.insertId}`);
                        res.json({ msg: `Successfully created competition: ${name}`, id: result.insertId });
                    }
                );
            }
        );
    } else {
        connection.query(
            `INSERT INTO competitions (name, description, date, event_type_id, status, created_at) VALUES (?, ?, ?, NULL, 'active', NOW())`, 
            [name.trim(), description.trim(), date || null],
            (err, result) => {
                if (err) return handleError(res, err, 'Failed to create competition');
                console.log(`Created competition: ${name} with ID: ${result.insertId}`);
                res.json({ msg: `Successfully created competition: ${name}`, id: result.insertId });
            }
        );
    }
});

app.put('/api/competitions/:id', (req, res) => {
    const { id } = req.params;
    const { name, description, date, event_type } = req.body;
    console.log(`PUT /api/competitions/${id}:`, req.body);
    
    if (!name || name.trim() === '' || !description || description.trim() === '') {
        return res.status(400).json({ msg: 'Name and description are required' });
    }
    
    // Find event_type_id if event_type is provided
    if (event_type) {
        connection.query(
            `SELECT id FROM event_types WHERE name = ?`,
            [event_type],
            (err, eventTypeResult) => {
                if (err) return handleError(res, err, 'Failed to find event type');
                
                const eventTypeId = eventTypeResult.length > 0 ? eventTypeResult[0].id : null;
                
                connection.query(
                    `UPDATE competitions SET name = ?, description = ?, date = ?, event_type_id = ?, updated_at = NOW() WHERE id = ?`,
                    [name.trim(), description.trim(), date || null, eventTypeId, id],
                    (err, result) => {
                        if (err) return handleError(res, err, 'Failed to update competition');
                        if (result.affectedRows === 0) {
                            return res.status(404).json({ msg: 'Competition not found' });
                        }
                        console.log(`Updated competition ID: ${id}`);
                        res.json({ msg: `Successfully updated competition: ${name}` });
                    }
                );
            }
        );
    } else {
        connection.query(
            `UPDATE competitions SET name = ?, description = ?, date = ?, event_type_id = NULL, updated_at = NOW() WHERE id = ?`,
            [name.trim(), description.trim(), date || null, id],
            (err, result) => {
                if (err) return handleError(res, err, 'Failed to update competition');
                if (result.affectedRows === 0) {
                    return res.status(404).json({ msg: 'Competition not found' });
                }
                console.log(`Updated competition ID: ${id}`);
                res.json({ msg: `Successfully updated competition: ${name}` });
            }
        );
    }
});

app.delete('/api/competitions/:id', (req, res) => {
    const { id } = req.params;
    console.log(`DELETE /api/competitions/${id}`);
    
    connection.query(`DELETE FROM competitions WHERE id = ?`, [id], (err, result) => {
        if (err) return handleError(res, err, 'Failed to delete competition');
        if (result.affectedRows === 0) {
            return res.status(404).json({ msg: 'Competition not found' });
        }
        console.log(`Deleted competition ID: ${id}`);
        res.json({ msg: 'Competition deleted successfully' });
    });
});

// ============= JUDGES ENDPOINTS =============
app.get("/api/judges", (req, res) => {
    console.log('GET /api/judges requested');
    connection.query("SELECT * FROM judges ORDER BY created_at DESC", (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch judges');
        console.log(`Returned ${rows.length} judges`);
        res.json(rows);
    });
});

app.post('/api/judges', (req, res) => {
    const { name, email, expertise, phone, status } = req.body;
    console.log('POST /api/judges:', req.body);
    
    if (!name || name.trim() === '' || !email || email.trim() === '') {
        return res.status(400).json({ msg: 'Name and email are required' });
    }
    
    connection.query(
        `INSERT INTO judges (name, email, expertise, phone, status, created_at) VALUES (?, ?, ?, ?, ?, NOW())`, 
        [name.trim(), email.trim(), expertise?.trim() || null, phone?.trim() || null, status || 'active'],
        (err, result) => {
            if (err) {
                if (err.code === 'ER_DUP_ENTRY') {
                    return res.status(400).json({ msg: 'Email address already exists' });
                }
                return handleError(res, err, 'Failed to add judge');
            }
            console.log(`Added judge: ${name} with ID: ${result.insertId}`);
            res.json({ msg: `Successfully added judge: ${name}`, id: result.insertId });
        }
    );
});

app.put('/api/judges/:id', (req, res) => {
    const { id } = req.params;
    const { name, email, expertise, phone, status } = req.body;
    console.log(`PUT /api/judges/${id}:`, req.body);
    
    if (!name || name.trim() === '' || !email || email.trim() === '') {
        return res.status(400).json({ msg: 'Name and email are required' });
    }
    
    connection.query(
        `UPDATE judges SET name = ?, email = ?, expertise = ?, phone = ?, status = ?, updated_at = NOW() WHERE id = ?`,
        [name.trim(), email.trim(), expertise?.trim() || null, phone?.trim() || null, status || 'active', id],
        (err, result) => {
            if (err) {
                if (err.code === 'ER_DUP_ENTRY') {
                    return res.status(400).json({ msg: 'Email address already exists' });
                }
                return handleError(res, err, 'Failed to update judge');
            }
            if (result.affectedRows === 0) {
                return res.status(404).json({ msg: 'Judge not found' });
            }
            console.log(`Updated judge ID: ${id}`);
            res.json({ msg: `Successfully updated judge: ${name}` });
        }
    );
});

app.delete('/api/judges/:id', (req, res) => {
    const { id } = req.params;
    console.log(`DELETE /api/judges/${id}`);
    
    connection.query(`DELETE FROM judges WHERE id = ?`, [id], (err, result) => {
        if (err) return handleError(res, err, 'Failed to delete judge');
        if (result.affectedRows === 0) {
            return res.status(404).json({ msg: 'Judge not found' });
        }
        console.log(`Deleted judge ID: ${id}`);
        res.json({ msg: 'Judge deleted successfully' });
    });
});

// ============= PARTICIPANTS ENDPOINTS =============
app.get("/api/participants", (req, res) => {
    console.log('GET /api/participants requested');
    connection.query(`
        SELECT p.*, c.name as category 
        FROM participants p 
        LEFT JOIN competitions c ON p.competition_id = c.id 
        ORDER BY p.created_at DESC
    `, (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch participants');
        
        // Map the result to match expected format
        const participants = rows.map(row => ({
            id: row.id,
            name: row.name,
            course: row.course,
            category: row.category,
            contact: row.contact,
            age: row.age,
            year_level: row.year_level,
            status: row.status,
            created_at: row.created_at,
            updated_at: row.updated_at
        }));
        
        console.log(`Returned ${participants.length} participants`);
        res.json(participants);
    });
});

app.post('/api/participants', (req, res) => {
    const { name, course, category, contact, age, year_level, status } = req.body;
    console.log('POST /api/participants:', req.body);
    
    if (!name || name.trim() === '' || !course || course.trim() === '') {
        return res.status(400).json({ msg: 'Name and course are required' });
    }
    
    // Find competition_id if category is provided
    if (category) {
        connection.query(
            `SELECT id FROM competitions WHERE name = ?`,
            [category],
            (err, competitionResult) => {
                if (err) return handleError(res, err, 'Failed to find competition');
                
                const competitionId = competitionResult.length > 0 ? competitionResult[0].id : null;
                
                connection.query(
                    `INSERT INTO participants (name, course, competition_id, contact, age, year_level, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())`, 
                    [name.trim(), course.trim(), competitionId, contact?.trim() || null, age || null, year_level?.trim() || null, status || 'active'],
                    (err, result) => {
                        if (err) return handleError(res, err, 'Failed to add participant');
                        console.log(`Added participant: ${name} with ID: ${result.insertId}`);
                        res.json({ msg: `Successfully added participant: ${name}`, id: result.insertId });
                    }
                );
            }
        );
    } else {
        connection.query(
            `INSERT INTO participants (name, course, competition_id, contact, age, year_level, status, created_at) VALUES (?, ?, NULL, ?, ?, ?, ?, NOW())`, 
            [name.trim(), course.trim(), contact?.trim() || null, age || null, year_level?.trim() || null, status || 'active'],
            (err, result) => {
                if (err) return handleError(res, err, 'Failed to add participant');
                console.log(`Added participant: ${name} with ID: ${result.insertId}`);
                res.json({ msg: `Successfully added participant: ${name}`, id: result.insertId });
            }
        );
    }
});

app.put('/api/participants/:id', (req, res) => {
    const { id } = req.params;
    const { name, course, category, contact, age, year_level, status } = req.body;
    console.log(`PUT /api/participants/${id}:`, req.body);
    
    if (!name || name.trim() === '' || !course || course.trim() === '') {
        return res.status(400).json({ msg: 'Name and course are required' });
    }
    
    // Find competition_id if category is provided
    if (category) {
        connection.query(
            `SELECT id FROM competitions WHERE name = ?`,
            [category],
            (err, competitionResult) => {
                if (err) return handleError(res, err, 'Failed to find competition');
                
                const competitionId = competitionResult.length > 0 ? competitionResult[0].id : null;
                
                connection.query(
                    `UPDATE participants SET name = ?, course = ?, competition_id = ?, contact = ?, age = ?, year_level = ?, status = ?, updated_at = NOW() WHERE id = ?`,
                    [name.trim(), course.trim(), competitionId, contact?.trim() || null, age || null, year_level?.trim() || null, status || 'active', id],
                    (err, result) => {
                        if (err) return handleError(res, err, 'Failed to update participant');
                        if (result.affectedRows === 0) {
                            return res.status(404).json({ msg: 'Participant not found' });
                        }
                        console.log(`Updated participant ID: ${id}`);
                        res.json({ msg: `Successfully updated participant: ${name}` });
                    }
                );
            }
        );
    } else {
        connection.query(
            `UPDATE participants SET name = ?, course = ?, competition_id = NULL, contact = ?, age = ?, year_level = ?, status = ?, updated_at = NOW() WHERE id = ?`,
            [name.trim(), course.trim(), contact?.trim() || null, age || null, year_level?.trim() || null, status || 'active', id],
            (err, result) => {
                if (err) return handleError(res, err, 'Failed to update participant');
                if (result.affectedRows === 0) {
                    return res.status(404).json({ msg: 'Participant not found' });
                }
                console.log(`Updated participant ID: ${id}`);
                res.json({ msg: `Successfully updated participant: ${name}` });
            }
        );
    }
});

app.delete('/api/participants/:id', (req, res) => {
    const { id } = req.params;
    console.log(`DELETE /api/participants/${id}`);
    
    connection.query(`DELETE FROM participants WHERE id = ?`, [id], (err, result) => {
        if (err) return handleError(res, err, 'Failed to delete participant');
        if (result.affectedRows === 0) {
            return res.status(404).json({ msg: 'Participant not found' });
        }
        console.log(`Deleted participant ID: ${id}`);
        res.json({ msg: 'Participant deleted successfully' });
    });
});

// ============= CRITERIA ENDPOINTS =============
app.get("/api/criteria", (req, res) => {
    console.log('GET /api/criteria requested');
    connection.query(`
        SELECT cr.*, c.name as competition 
        FROM criteria cr 
        LEFT JOIN competitions c ON cr.competition_id = c.id 
        ORDER BY cr.created_at DESC
    `, (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch criteria');
        
        // Map the result to match expected format
        const criteria = rows.map(row => ({
            id: row.id,
            name: row.name,
            description: row.description,
            max_score: row.max_score,
            weight: row.weight,
            competition: row.competition,
            created_at: row.created_at,
            updated_at: row.updated_at
        }));
        
        console.log(`Returned ${criteria.length} criteria`);
        res.json(criteria);
    });
});

app.post('/api/criteria', (req, res) => {
    const { name, description, max_score, weight, competition } = req.body;
    console.log('POST /api/criteria:', req.body);
    
    if (!name || name.trim() === '') {
        return res.status(400).json({ msg: 'Name is required' });
    }
    
    const score = max_score || 100;
    if (score <= 0 || score > 100) {
        return res.status(400).json({ msg: 'Max score must be between 1 and 100' });
    }
    
    // Find competition_id if competition is provided
    if (competition) {
        connection.query(
            `SELECT id FROM competitions WHERE name = ?`,
            [competition],
            (err, competitionResult) => {
                if (err) return handleError(res, err, 'Failed to find competition');
                
                const competitionId = competitionResult.length > 0 ? competitionResult[0].id : null;
                
                connection.query(
                    `INSERT INTO criteria (name, description, max_score, weight, competition_id, created_at) VALUES (?, ?, ?, ?, ?, NOW())`, 
                    [name.trim(), description?.trim() || null, score, weight || 1.00, competitionId],
                    (err, result) => {
                        if (err) return handleError(res, err, 'Failed to create criteria');
                        console.log(`Created criteria: ${name} with ID: ${result.insertId}`);
                        res.json({ msg: `Successfully created criteria: ${name}`, id: result.insertId });
                    }
                );
            }
        );
    } else {
        return res.status(400).json({ msg: 'Competition is required' });
    }
});

app.put('/api/criteria/:id', (req, res) => {
    const { id } = req.params;
    const { name, description, max_score, weight, competition } = req.body;
    console.log(`PUT /api/criteria/${id}:`, req.body);
    
    if (!name || name.trim() === '') {
        return res.status(400).json({ msg: 'Name is required' });
    }
    
    const score = max_score || 100;
    if (score <= 0 || score > 100) {
        return res.status(400).json({ msg: 'Max score must be between 1 and 100' });
    }
    
    // Find competition_id if competition is provided
    if (competition) {
        connection.query(
            `SELECT id FROM competitions WHERE name = ?`,
            [competition],
            (err, competitionResult) => {
                if (err) return handleError(res, err, 'Failed to find competition');
                
                const competitionId = competitionResult.length > 0 ? competitionResult[0].id : null;
                
                connection.query(
                    `UPDATE criteria SET name = ?, description = ?, max_score = ?, weight = ?, competition_id = ?, updated_at = NOW() WHERE id = ?`,
                    [name.trim(), description?.trim() || null, score, weight || 1.00, competitionId, id],
                    (err, result) => {
                        if (err) return handleError(res, err, 'Failed to update criteria');
                        if (result.affectedRows === 0) {
                            return res.status(404).json({ msg: 'Criteria not found' });
                        }
                        console.log(`Updated criteria ID: ${id}`);
                        res.json({ msg: `Successfully updated criteria: ${name}` });
                    }
                );
            }
        );
    } else {
        return res.status(400).json({ msg: 'Competition is required' });
    }
});

app.delete('/api/criteria/:id', (req, res) => {
    const { id } = req.params;
    console.log(`DELETE /api/criteria/${id}`);
    
    connection.query(`DELETE FROM criteria WHERE id = ?`, [id], (err, result) => {
        if (err) return handleError(res, err, 'Failed to delete criteria');
        if (result.affectedRows === 0) {
            return res.status(404).json({ msg: 'Criteria not found' });
        }
        console.log(`Deleted criteria ID: ${id}`);
        res.json({ msg: 'Criteria deleted successfully' });
    });
});



//serrver
app.listen(PORT,  () => {
    console.log(`=================================`);
    console.log(`Server running on port ${PORT}`);
    console.log(`Local: http://localhost:${PORT}`);
    console.log(`=================================`);
});
