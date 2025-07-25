INSERT INTO holiday_packages (destination, price, duration_days, availability, description)
VALUES ('Bali, Indonesia', 1299.99, 7, 15, 'Tropical paradise with beautiful beaches and rich culture'),
       ('Paris, France', 899.50, 5, 8, 'City of love with iconic landmarks and world-class cuisine'),
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
