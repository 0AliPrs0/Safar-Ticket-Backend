    CREATE TABLE City (
        city_id BIGINT PRIMARY KEY AUTO_INCREMENT,
        province_name VARCHAR(100) NOT NULL,
        city_name VARCHAR(100) NOT NULL
        );

    CREATE TABLE User (
        user_id BIGINT PRIMARY KEY AUTO_INCREMENT,
        first_name VARCHAR(100) NOT NULL,
        last_name VARCHAR(100) NOT NULL,
        email VARCHAR(255) UNIQUE,
        phone_number VARCHAR(20) UNIQUE,
        user_type ENUM('CUSTOMER', 'ADMIN') NOT NULL,
        city VARCHAR(100),
        password_hash VARCHAR(255) NOT NULL,
        registration_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        account_status ENUM('ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE',
        CHECK (email IS NOT NULL OR phone_number IS NOT NULL),
        CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' OR email IS NULL),
        CHECK (phone_number REGEXP '^[0-9]{10,15}$' OR phone_number IS NULL)
    );

    ALTER TABLE User
        DROP COLUMN city;

    ALTER TABLE User
        ADD COLUMN city_id BIGINT NOT NULL;

    ALTER TABLE User
        ADD COLUMN birth_date Date NULL;
        
    ALTER TABLE User
        ADD CONSTRAINT fk_city
            FOREIGN KEY (city_id) REFERENCES City(city_id)
            ON DELETE CASCADE;

    CREATE TABLE Terminal (
    terminal_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    city_id BIGINT NOT NULL,
    terminal_name VARCHAR(100) NOT NULL,
    terminal_type ENUM('airport', 'bus_terminal', 'train_station') NOT NULL,
    FOREIGN KEY (city_id) REFERENCES City(city_id) ON DELETE CASCADE
        );

    CREATE TABLE TransportCompany (
        transport_company_id BIGINT PRIMARY KEY AUTO_INCREMENT,
        company_name VARCHAR(100) NOT NULL,
        transport_type ENUM('airplane', 'bus', 'train') NOT NULL
    );

    CREATE TABLE Travel (
        travel_id BIGINT PRIMARY KEY AUTO_INCREMENT,
        transport_type ENUM('plane', 'train', 'bus') NOT NULL,
        departure VARCHAR(50) NOT NULL,
        destination VARCHAR(50) NOT NULL,
        departure_time DATETIME NOT NULL,
        arrival_time DATETIME NOT NULL,
        total_capacity INT NOT NULL,
        remaining_capacity INT NOT NULL,
        transport_company_id BIGINT NULL,
        price INT NOT NULL,
        is_round_trip BOOLEAN,
        CHECK(price >= 0),
        travel_class ENUM('economy', 'business', 'VIP') NOT NULL
    );

    ALTER TABLE Travel
        DROP COLUMN departure,
        DROP COLUMN destination;

    ALTER TABLE Travel
        ADD COLUMN departure_terminal_id BIGINT NOT NULL,
        ADD COLUMN destination_terminal_id BIGINT NOT NULL;

    ALTER TABLE Travel
        ADD CONSTRAINT fk_departure_terminal
            FOREIGN KEY (departure_terminal_id) REFERENCES Terminal(terminal_id)
            ON DELETE CASCADE,
        ADD CONSTRAINT fk_destination_terminal
            FOREIGN KEY (destination_terminal_id) REFERENCES Terminal(terminal_id)
            ON DELETE CASCADE;

    ALTER TABLE Travel
        ADD CONSTRAINT fk_travel_company
            FOREIGN KEY (transport_company_id) REFERENCES TransportCompany(transport_company_id)
            ON DELETE CASCADE;

    CREATE TABLE VehicleDetail (
        vehicle_id BIGINT PRIMARY KEY AUTO_INCREMENT,
        vehicle_type ENUM('train', 'flight', 'bus') NOT NULL
    );

    CREATE TABLE TrainDetail (
        train_id BIGINT PRIMARY KEY,
        train_rating ENUM('3', '4', '5') NOT NULL,
        private_cabin BOOLEAN,
        facilities JSON,
        FOREIGN KEY (train_id) REFERENCES VehicleDetail(vehicle_id) ON DELETE CASCADE
    );

    CREATE TABLE BusDetail (
        bus_id BIGINT PRIMARY KEY,
        bus_company VARCHAR(255) NOT NULL,
        bus_type ENUM('VIP', 'regular', 'sleeper') NOT NULL,
        facilities JSON,
        seat_arrangement ENUM('1+2', '2+2') NOT NULL,
        FOREIGN KEY (bus_id) REFERENCES VehicleDetail(vehicle_id) ON DELETE CASCADE
    );

    CREATE TABLE FlightDetail (
        flight_id BIGINT PRIMARY KEY,
        airline_name VARCHAR(255) NOT NULL,
        flight_class ENUM('economy', 'business', 'first_class') NOT NULL,
        stops INT NOT NULL DEFAULT 0,
        flight_number VARCHAR(50) UNIQUE NOT NULL,
        origin_airport VARCHAR(255) NOT NULL,
        destination_airport VARCHAR(255) NOT NULL,
        facilities JSON,
        FOREIGN KEY (flight_id) REFERENCES VehicleDetail(vehicle_id) ON DELETE CASCADE
    );

    CREATE TABLE Ticket (
        ticket_id BIGINT PRIMARY KEY AUTO_INCREMENT,
        travel_id BIGINT NOT NULL,
        vehicle_id BIGINT NOT NULL,
        seat_number INT NOT NULL,
        FOREIGN KEY (travel_id) REFERENCES Travel(travel_id) ON DELETE CASCADE,
        FOREIGN KEY (vehicle_id) REFERENCES VehicleDetail(vehicle_id) ON DELETE CASCADE
    );

    CREATE TABLE Reservation (
        reservation_id BIGINT PRIMARY KEY AUTO_INCREMENT,
        user_id BIGINT NOT NULL,
        ticket_id BIGINT NOT NULL,
        status ENUM('reserved', 'paid', 'canceled') NOT NULL,
        reservation_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        expiration_time DATETIME NOT NULL,
        CHECK (expiration_time >= reservation_time),
        FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE CASCADE,
        FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id) ON DELETE CASCADE
    );

    CREATE TABLE Payment (
        payment_id BIGINT PRIMARY KEY AUTO_INCREMENT,
        user_id BIGINT NOT NULL,
        reservation_id BIGINT UNIQUE NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        payment_method ENUM('credit_card', 'wallet', 'crypto') NOT NULL,
        payment_status ENUM('failed', 'pending', 'completed') NOT NULL,
        payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE CASCADE,
        FOREIGN KEY (reservation_id) REFERENCES Reservation(reservation_id) ON DELETE CASCADE
    );

    CREATE TABLE Report (
        report_id BIGINT PRIMARY KEY AUTO_INCREMENT,
        user_id BIGINT NOT NULL,
        ticket_id BIGINT NOT NULL,
        report_category ENUM('payment_issue', 'travel_delay', 'unexpected_cancellation', 'other') NOT NULL,
        report_text TEXT NOT NULL,
        status ENUM('reviewed', 'pending') NOT NULL,
        report_time DATETIME NOT NULL,
        FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE CASCADE,
        FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id) ON DELETE CASCADE
    );

    CREATE TABLE ReservationChange (
        reservation_change_id BIGINT PRIMARY KEY AUTO_INCREMENT,
        reservation_id BIGINT NOT NULL,
        support_id BIGINT NOT NULL,
        prev_status ENUM('reserved', 'paid', 'canceled') NOT NULL,
        next_status ENUM('reserved', 'paid', 'canceled') NOT NULL,
        FOREIGN KEY (reservation_id) REFERENCES Reservation(reservation_id) ON DELETE CASCADE,
        FOREIGN KEY (support_id) REFERENCES User(user_id) ON DELETE CASCADE
        );

    INSERT INTO City (province_name, city_name) VALUES
    ('Tehran', 'Tehran'),
    ('Razavi Khorasan', 'Mashhad'),
    ('Isfahan', 'Isfahan'),
    ('Alborz', 'Karaj'),
    ('Fars', 'Shiraz'),
    ('East Azerbaijan', 'Tabriz'),
    ('Qom', 'Qom'),
    ('Khuzestan', 'Ahvaz'),
    ('Kermanshah', 'Kermanshah'),
    ('West Azerbaijan', 'Urmia'),
    ('Gilan', 'Rasht'),
    ('Sistan and Baluchestan', 'Zahedan'),
    ('Hamadan', 'Hamadan'),
    ('Kerman', 'Kerman'),
    ('Yazd', 'Yazd'),
    ('Ardabil', 'Ardabil'),
    ('Hormozgan', 'Bandar Abbas'),
    ('Markazi', 'Arak'),
    ('Zanjan', 'Zanjan');

    INSERT INTO City (province_name, city_name) VALUES
    ('Kermanshah', 'Kermanshah'),
    ('Kohgiluyeh and Boyer-Ahmad', 'Yasuj'),
    ('Kurdistan', 'Sanandaj'),
    ('Lorestan', 'Khorramabad'),
    ('Mazandaran', 'Sari'),
    ('North Khorasan', 'Bojnord'),
    ('Qazvin', 'Qazvin'),
    ('Semnan', 'Semnan'),
    ('South Khorasan', 'Birjand'),
    ('West Azerbaijan', 'Khoy'),
    ('East Azerbaijan', 'Maragheh'),
    ('Golestan', 'Gorgan'),
    ('Hormozgan', 'Bandar Lengeh'),
    ('Ilam', 'Ilam'),
    ('Kerman', 'Bam'),
    ('Khorasan Razavi', 'Sabzevar'),
    ('Markazi', 'Saveh'),
    ('Mazandaran', 'Amol'),
    ('Qom', 'Qom'),
    ('Yazd', 'Meybod');

    INSERT INTO City (province_name, city_name) VALUES
    ('East Azerbaijan', 'Marand'),
    ('Fars', 'Marvdasht'),
    ('Gilan', 'Bandar Anzali'),
    ('Golestan', 'Gonbad-e Kavus'),
    ('Hamadan', 'Malayer'),
    ('Hormozgan', 'Minab'),
    ('Isfahan', 'Khomeyni Shahr'),
    ('Kerman', 'Rafsanjan'),
    ('Razavi Khorasan', 'Neyshabur'),
    ('Khuzestan', 'Dezful'),
    ('Khuzestan', 'Abadan'),
    ('Lorestan', 'Borujerd'),
    ('Mazandaran', 'Babol'),
    ('Mazandaran', 'Qaemshahr'),
    ('Qazvin', 'Takestan'),
    ('Semnan', 'Shahrud'),
    ('Sistan and Baluchestan', 'Chabahar'),
    ('West Azerbaijan', 'Mahabad'),
    ('Yazd', 'Ardakan'),
    ('North Khorasan', 'Shirvan');

    INSERT INTO City (province_name, city_name) VALUES
    ('Tehran', 'Shahr-e Qods'),
    ('Tehran', 'Varamin'),
    ('Tehran', 'Eslamshahr'),
    ('Tehran', 'Pakdasht');

    INSERT INTO User (first_name, last_name, email, phone_number, user_type, city_id, password_hash, registration_date, account_status)
    VALUES
    ('admin', 'admin', 'admin@gmail.com', '0000000000', 'ADMIN', 1, 'hashed_password_0', NOW(), 'ACTIVE'),
    ('John', 'Doe', 'john.doe@example.com', '1234567890', 'CUSTOMER', 12, 'hashed_password_1', NOW(), 'ACTIVE'),
    ('Alice', 'Smith', 'alice.smith@example.com', '2345678901', 'ADMIN', 14, 'hashed_password_2', NOW(), 'ACTIVE'),
    ('Bob', 'Brown', 'bob.brown@example.com', '3456789012', 'ADMIN', 16, 'hashed_password_3', NOW(), 'ACTIVE'),
    ('Charlie', 'Johnson', 'charlie.johnson@example.com', '4567890123', 'CUSTOMER', 18, 'hashed_password_4', NOW(), 'ACTIVE'),
    ('David', 'Wilson', 'david.wilson@example.com', '5678901234', 'CUSTOMER', 20, 'hashed_password_5', NOW(), 'ACTIVE'),
    ('Emma', 'Taylor', 'emma.taylor@example.com', '6789012345', 'ADMIN', 22, 'hashed_password_6', NOW(), 'ACTIVE'),
    ('Frank', 'Anderson', 'frank.anderson@example.com', '7890123456', 'ADMIN', 24, 'hashed_password_7', NOW(), 'ACTIVE'),
    ('Grace', 'Martinez', 'grace.martinez@example.com', '8901234567', 'CUSTOMER', 26, 'hashed_password_8', NOW(), 'ACTIVE'),
    ('Henry', 'Thomas', 'henry.thomas@example.com', '9012345678', 'CUSTOMER', 28, 'hashed_password_9', NOW(), 'ACTIVE'),
    ('Isabel', 'White', 'isabel.white@example.com', '0123456789', 'ADMIN', 30, 'hashed_password_10', NOW(), 'ACTIVE'),
    ('Ali', 'Prs', 'ali@gmail.com', '9032948208', 'CUSTOMER', 32, '6bce8c09ce07cd1114acfdf2caa22202a403c4a2b83b27233f0705c54676bed9', NOW(), 'ACTIVE'),
    ('Mehdi', 'Salman', 'mehdi@gmail.com', '9938634096', 'CUSTOMER', 34, 'a956be05d5b1a7738549eb274626b01e663bf30111994d91e2384ddbb0dc292c', NOW(), 'ACTIVE');

    UPDATE User SET birth_date = '1995-03-10' WHERE user_id = 1;
    UPDATE User SET birth_date = '1988-07-22' WHERE user_id = 2;
    UPDATE User SET birth_date = '1992-11-15' WHERE user_id = 3;
    UPDATE User SET birth_date = '1990-05-30' WHERE user_id = 4;
    UPDATE User SET birth_date = '1985-09-18' WHERE user_id = 5;
    UPDATE User SET birth_date = '1998-12-05' WHERE user_id = 6;
    UPDATE User SET birth_date = '1993-04-25' WHERE user_id = 7;
    UPDATE User SET birth_date = '1987-08-14' WHERE user_id = 8;
    UPDATE User SET birth_date = '1991-01-20' WHERE user_id = 9;
    UPDATE User SET birth_date = '1994-06-08' WHERE user_id = 10;
    UPDATE User SET birth_date = '1989-10-12' WHERE user_id = 11;
    UPDATE User SET birth_date = '1997-02-28' WHERE user_id = 12;
    UPDATE User SET birth_date = '1996-07-03' WHERE user_id = 13;

    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (1, 'Imam Khomeini International Airport', 'airport'),
    (1, 'Mehrabad Airport', 'airport'),
    (1, 'Tehran Railway Station', 'train_station'),
    (1, 'South Terminal', 'bus_terminal'),
    (1, 'West Terminal', 'bus_terminal'),
    (1, 'East Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (2, 'Mashhad International Airport', 'airport'),
    (2, 'Mashhad Railway Station', 'train_station'),
    (2, 'Imam Reza Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (3, 'Isfahan International Airport', 'airport'),
    (3, 'Isfahan Railway Station', 'train_station'),
    (3, 'Kaveh Terminal', 'bus_terminal'),
    (3, 'Sofeh Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (4, 'Karaj Railway Station', 'train_station'),
    (4, 'Karaj Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (5, 'Shiraz International Airport', 'airport'),
    (5, 'Shiraz Railway Station', 'train_station'),
    (5, 'Shiraz Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (6, 'Tabriz International Airport', 'airport'),
    (6, 'Tabriz Railway Station', 'train_station'),
    (6, 'Tabriz Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (7, 'Qom Railway Station', 'train_station'),
    (7, 'Qom Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (8, 'Ahvaz International Airport', 'airport'),
    (8, 'Ahvaz Railway Station', 'train_station'),
    (8, 'Ahvaz Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (9, 'Kermanshah International Airport', 'airport'),
    (9, 'Kermanshah Railway Station', 'train_station'),
    (9, 'Kermanshah Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (10, 'Urmia International Airport', 'airport'),
    (10, 'Urmia Railway Station', 'train_station'),
    (10, 'Urmia Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (11, 'Rasht International Airport', 'airport'),
    (11, 'Rasht Railway Station', 'train_station'),
    (11, 'Rasht Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (12, 'Zahedan International Airport', 'airport'),
    (12, 'Zahedan Railway Station', 'train_station'),
    (12, 'Zahedan Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (13, 'Hamadan International Airport', 'airport'),
    (13, 'Hamadan Railway Station', 'train_station'),
    (13, 'Hamadan Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (14, 'Kerman International Airport', 'airport'),
    (14, 'Kerman Railway Station', 'train_station'),
    (14, 'Kerman Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (15, 'Yazd International Airport', 'airport'),
    (15, 'Yazd Railway Station', 'train_station'),
    (15, 'Yazd Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (16, 'Ardabil International Airport', 'airport'),
    (16, 'Ardabil Railway Station', 'train_station'),
    (16, 'Ardabil Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (17, 'Bandar Abbas International Airport', 'airport'),
    (17, 'Bandar Abbas Railway Station', 'train_station'),
    (17, 'Bandar Abbas Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (18, 'Arak International Airport', 'airport'),
    (18, 'Arak Railway Station', 'train_station'),
    (18, 'Arak Terminal', 'bus_terminal');

    
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (19, 'Zanjan International Airport', 'airport'),
    (19, 'Zanjan Railway Station', 'train_station'),
    (19, 'Zanjan Terminal', 'bus_terminal');


    -- Yasuj
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (20, 'Yasuj Airport', 'airport'),
    (20, 'Yasuj Terminal', 'bus_terminal');

    -- Sanandaj
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (21, 'Sanandaj Airport', 'airport'),
    (21, 'Sanandaj Railway Station', 'train_station'),
    (21, 'Sanandaj Terminal', 'bus_terminal');

    -- Khorramabad
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (22, 'Khorramabad Airport', 'airport'),
    (22, 'Khorramabad Terminal', 'bus_terminal');

    -- Sari
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (23, 'Dasht-e Naz Airport', 'airport'),
    (23, 'Sari Railway Station', 'train_station'),
    (23, 'Sari Terminal', 'bus_terminal');

    -- Bojnord
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (24, 'Bojnord Airport', 'airport'),
    (24, 'Bojnord Terminal', 'bus_terminal');

    -- Qazvin
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (25, 'Qazvin Airport', 'airport'),
    (25, 'Qazvin Railway Station', 'train_station'),
    (25, 'Qazvin Terminal', 'bus_terminal');

    -- Semnan
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (26, 'Semnan Airport', 'airport'),
    (26, 'Semnan Railway Station', 'train_station'),
    (26, 'Semnan Terminal', 'bus_terminal');

    -- Birjand
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (27, 'Birjand Airport', 'airport'),
    (27, 'Birjand Terminal', 'bus_terminal');

    -- Khoy
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (28, 'Khoy Airport', 'airport'),
    (28, 'Khoy Terminal', 'bus_terminal');

    -- Maragheh
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (29, 'Maragheh Airport', 'airport'),
    (29, 'Maragheh Terminal', 'bus_terminal');

    -- Gorgan
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (30, 'Gorgan Airport', 'airport'),
    (30, 'Gorgan Railway Station', 'train_station'),
    (30, 'Gorgan Terminal', 'bus_terminal');

    -- Bandar Lengeh
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (31, 'Bandar Lengeh Airport', 'airport'),
    (31, 'Bandar Lengeh Terminal', 'bus_terminal');

    -- Ilam
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (32, 'Ilam Airport', 'airport'),
    (32, 'Ilam Terminal', 'bus_terminal');

    -- Bam
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (33, 'Bam Airport', 'airport'),
    (33, 'Bam Terminal', 'bus_terminal');

    -- Sabzevar
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (34, 'Sabzevar Airport', 'airport'),
    (34, 'Sabzevar Railway Station', 'train_station'),
    (34, 'Sabzevar Terminal', 'bus_terminal');

    -- Saveh
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (35, 'Saveh Airport', 'airport'),
    (35, 'Saveh Terminal', 'bus_terminal');

    -- Amol
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (36, 'Amol Airport', 'airport'),
    (36, 'Amol Terminal', 'bus_terminal');

    -- Meybod
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (37, 'Meybod Terminal', 'bus_terminal');


    -- Marand (bus terminal only)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (38, 'Marand Terminal', 'bus_terminal');

    -- Marvdasht (bus terminal only)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (39, 'Marvdasht Terminal', 'bus_terminal');

    -- Bandar Anzali (airport + bus terminal)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (40, 'Bandar Anzali Airport', 'airport'),
    (40, 'Bandar Anzali Terminal', 'bus_terminal');

    -- Gonbad-e Kavus (airport + bus terminal)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (41, 'Gonbad-e Kavus Airport', 'airport'),
    (41, 'Gonbad-e Kavus Terminal', 'bus_terminal');

    -- Malayer (bus terminal only)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (42, 'Malayer Terminal', 'bus_terminal');

    -- Minab (airport + bus terminal)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (43, 'Minab Airport', 'airport'),
    (43, 'Minab Terminal', 'bus_terminal');

    -- Khomeyni Shahr (bus terminal only)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (44, 'Khomeyni Shahr Terminal', 'bus_terminal');

    -- Rafsanjan (airport + bus terminal)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (45, 'Rafsanjan Airport', 'airport'),
    (45, 'Rafsanjan Terminal', 'bus_terminal');

    -- Neyshabur (train station + bus terminal)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (46, 'Neyshabur Railway Station', 'train_station'),
    (46, 'Neyshabur Terminal', 'bus_terminal');

    -- Dezful (airport + train + bus)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (47, 'Dezful Airport', 'airport'),
    (47, 'Dezful Railway Station', 'train_station'),
    (47, 'Dezful Terminal', 'bus_terminal');

    -- Abadan (airport + train + bus)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (48, 'Abadan Airport', 'airport'),
    (48, 'Abadan Railway Station', 'train_station'),
    (48, 'Abadan Terminal', 'bus_terminal');

    -- Borujerd (train + bus)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (49, 'Borujerd Railway Station', 'train_station'),
    (49, 'Borujerd Terminal', 'bus_terminal');

    -- Babol (bus terminal only)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (50, 'Babol Terminal', 'bus_terminal');

    -- Qaemshahr (bus terminal only)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (51, 'Qaemshahr Terminal', 'bus_terminal');

    -- Takestan (bus terminal only)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (52, 'Takestan Terminal', 'bus_terminal');

    -- Shahrud (airport + train + bus)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (53, 'Shahrud Airport', 'airport'),
    (53, 'Shahrud Railway Station', 'train_station'),
    (53, 'Shahrud Terminal', 'bus_terminal');

    -- Chabahar (airport + bus)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (54, 'Chabahar Airport', 'airport'),
    (54, 'Chabahar Terminal', 'bus_terminal');

    -- Mahabad (bus terminal only)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (55, 'Mahabad Terminal', 'bus_terminal');

    -- Ardakan (bus terminal only)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (56, 'Ardakan Terminal', 'bus_terminal');

    -- Shirvan (replacement city - airport + bus)
    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (57, 'Shirvan Airport', 'airport'),
    (57, 'Shirvan Terminal', 'bus_terminal');

    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (60, 'Shahr-e Qods Terminal', 'bus_terminal');

    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (61, 'Varamin Terminal', 'bus_terminal');

    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (62, 'Eslamshahr Terminal', 'bus_terminal');

    INSERT INTO Terminal (city_id, terminal_name, terminal_type) VALUES
    (63, 'Pakdasht Terminal', 'bus_terminal');

    INSERT INTO TransportCompany (company_name, transport_type) VALUES
    ('Iran Bus Co.', 'bus'),
    ('Tehran Transport', 'bus'),
    ('Safar Bus Lines', 'bus'),
    ('Pars Travel', 'bus'),
    ('Aria Bus Co.', 'bus'),
    ('Asia Road Lines', 'bus'),
    ('Kavir Bus', 'bus'),
    ('Seir-o-Safar', 'bus'),
    ('Royal Bus Group', 'bus'),
    ('Shahr-e-Farang Transport', 'bus');

    INSERT INTO TransportCompany (company_name, transport_type) VALUES
    ('Iran Railways', 'train'),
    ('Pars Rail Co.', 'train'),
    ('Golden Rail', 'train'),
    ('Arman Railways', 'train'),
    ('Tehran Express', 'train'),
    ('Asia Train Co.', 'train'),
    ('RailNav Co.', 'train'),
    ('TBT Rail', 'train'),
    ('Shiraz Railways', 'train'),
    ('GreenRail Services', 'train');

    INSERT INTO TransportCompany (company_name, transport_type) VALUES
    ('Iran Air', 'airplane'),
    ('Mahan Air', 'airplane'),
    ('Caspian Airlines', 'airplane'),
    ('Qeshm Air', 'airplane'),
    ('Zagros Airlines', 'airplane'),
    ('Aseman Airlines', 'airplane'),
    ('Sepehran Air', 'airplane'),
    ('Taban Air', 'airplane'),
    ('Kish Air', 'airplane'),
    ('Pars Air', 'airplane');


    INSERT INTO Travel (transport_type, departure_terminal_id, destination_terminal_id, departure_time, arrival_time, total_capacity, remaining_capacity, transport_company_id, price, is_round_trip, travel_class)
    VALUES
    ('plane', 31, 1, NOW(), DATE_ADD(NOW(), INTERVAL 5 HOUR), 200, 150, 1, 300, true, 'business'),
    ('train', 32, 1, NOW(), DATE_ADD(NOW(), INTERVAL 3 HOUR), 150, 100, 2, 100, false, 'economy'),
    ('bus', 33, 2, NOW(), DATE_ADD(NOW(), INTERVAL 8 HOUR), 50, 30, 3, 50, false, 'VIP'),
    ('plane', 34, 3, NOW(), DATE_ADD(NOW(), INTERVAL 4 HOUR), 180, 120, 4, 250, true, 'economy'),
    ('train', 35, 4, NOW(), DATE_ADD(NOW(), INTERVAL 6 HOUR), 130, 90, 5, 120, false, 'business'),
    ('bus', 36, 19, NOW(), DATE_ADD(NOW(), INTERVAL 10 HOUR), 60, 40, 6, 60, false, 'economy'),
    ('plane', 37, 29, NOW(), DATE_ADD(NOW(), INTERVAL 2 HOUR), 220, 180, 7, 200, true, 'VIP'),
    ('train', 38, 21, NOW(), DATE_ADD(NOW(), INTERVAL 5 HOUR), 140, 100, 8, 80, false, 'economy'),
    ('bus', 39, 12, NOW(), DATE_ADD(NOW(), INTERVAL 9 HOUR), 70, 50, 9, 55, false, 'VIP'),
    ('plane', 40, 79, NOW(), DATE_ADD(NOW(), INTERVAL 5 HOUR), 210, 170, 10, 275, true, 'business');

    UPDATE Travel
    SET Travel.departure_terminal_id = Travel.departure_terminal_id + 104
    WHERE Travel.travel_id < 3;

    INSERT INTO VehicleDetail (vehicle_type)
    VALUES
    ('train'), ('flight'), ('bus'), ('train'), ('flight'), ('bus'), ('train'), ('flight'), ('bus'), ('train');

    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES
    (3, 'Greyhound', 'VIP', '{"reclining_seats": true, "usb_ports": true}', '1+2'),
    (6, 'Megabus', 'regular', '{"wifi": false, "snacks": false}', '2+2'),
    (9, 'FlixBus', 'sleeper', '{"beds": true, "curtains": true}', '1+2');

    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES
    (2, 'American Airlines', 'business', 1, 'AA100', 'JFK', 'LAX', '{"entertainment": true, "extra_legroom": true}'),
    (5, 'Delta Airlines', 'economy', 0, 'DL200', 'ORD', 'DFW', '{"wifi": true, "snacks": true}'),
    (8, 'United Airlines', 'first_class', 2, 'UA300', 'MIA', 'SEA', '{"lounge_access": true, "priority_boarding": true}');

    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES
    (1, '5', true, '{"wifi": true, "meal": true}'),
    (4, '4', false, '{"wifi": false, "meal": true}'),
    (7, '3', true, '{"wifi": true, "meal": false}'),
    (10, '5', false, '{"wifi": true, "meal": true}');

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number)
    VALUES
    (1, 1, 10), (2, 2, 15), (3, 3, 5), (4, 4, 20), (5, 5, 30), (6, 6, 8), (7, 7, 18), (8, 8, 25), (9, 9, 35), (10, 10, 12);

    INSERT INTO Reservation (user_id, ticket_id, status, reservation_time, expiration_time)
    VALUES
    (1, 1, 'reserved', NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    (2, 2, 'paid', NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    (3, 3, 'canceled', NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    (4, 4, 'reserved', NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    (5, 5, 'paid', NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    (6, 6, 'canceled', NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    (7, 7, 'reserved', NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    (8, 8, 'paid', NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    (9, 9, 'canceled', NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    (10, 10, 'reserved', NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY));


    INSERT INTO Payment (user_id, reservation_id, amount, payment_method, payment_status, payment_date)
    VALUES
    (1, 1, 300.00, 'credit_card', 'completed', NOW()),
    (2, 2, 100.00, 'wallet', 'completed', NOW()),
    (3, 3, 50.00, 'crypto', 'failed', NOW()),
    (4, 4, 250.00, 'credit_card', 'pending', NOW()),
    (5, 5, 120.00, 'wallet', 'completed', NOW()),
    (6, 6, 60.00, 'crypto', 'completed', NOW()),
    (7, 7, 200.00, 'credit_card', 'failed', NOW()),
    (8, 8, 80.00, 'wallet', 'completed', NOW()),
    (9, 9, 55.00, 'crypto', 'pending', NOW()),
    (12, 10, 280.00, 'credit_card', 'completed', DATE_SUB(NOW(), INTERVAL 32 DAY));

    INSERT INTO Report (user_id, ticket_id, report_category, report_text, status, report_time)
    VALUES
    (1, 1, 'payment_issue', 'Payment failed unexpectedly.', 'pending', NOW()),
    (2, 2, 'travel_delay', 'Train delayed by 3 hours.', 'reviewed', NOW()),
    (2, 2, 'travel_delay', 'Train delayed by 2 hours.', 'reviewed', NOW()),
    (3, 3, 'unexpected_cancellation', 'My ticket was canceled without notice.', 'pending', NOW()),
    (4, 4, 'other', 'Seats were not comfortable.', 'reviewed', NOW()),
    (5, 5, 'payment_issue', 'Charged twice for the same ticket.', 'pending', NOW()),
    (6, 6, 'travel_delay', 'Bus arrived late by 2 hours.', 'reviewed', NOW()),
    (7, 7, 'unexpected_cancellation', 'Flight got canceled without reason.', 'pending', NOW()),
    (8, 8, 'other', 'Poor customer service.', 'reviewed', NOW()),
    (9, 9, 'payment_issue', 'Refund not processed yet.', 'pending', NOW()),
    (10, 10, 'travel_delay', 'Flight delay affected my schedule.', 'reviewed', NOW()),
    (1, 1, 'travel_delay', 'Payment failed unexpectedly.', 'pending', NOW()),
    (1, 1, 'travel_delay', 'Delayyyy', 'pending', NOW());

    INSERT INTO ReservationChange (reservation_id, support_id, prev_status, next_status)
    VALUES
    (1, 3, 'reserved', 'canceled'),
    (2, 3, 'paid', 'canceled'),
    (5, 7, 'paid', 'canceled'),
    (8, 3, 'paid', 'canceled');
        
