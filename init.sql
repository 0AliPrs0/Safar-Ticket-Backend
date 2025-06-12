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

    ALTER TABLE User ADD COLUMN wallet INT NOT NULL DEFAULT 0;

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

    ALTER TABLE Payment MODIFY COLUMN payment_status ENUM('failed', 'pending', 'completed', 'refunded') NOT NULL;

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

    ALTER TABLE Report ADD COLUMN report_response TEXT;

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
    ('admin', 'admin', 'admin@gmail.com', '0000000000', 'ADMIN', 1, '851aa83d4842d4595551a90421b030904f848b5002da05260195a59ecfb56b30', NOW(), 'ACTIVE'),
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
    ('Ali', 'Prs', 'aliprs138455@gmail.com', '9032948208', 'CUSTOMER', 32, '6bce8c09ce07cd1114acfdf2caa22202a403c4a2b83b27233f0705c54676bed9', NOW(), 'ACTIVE'),
    ('Mehdi', 'Salman', 'mahdisalman033@gmail.com', '9938634096', 'CUSTOMER', 34, 'a956be05d5b1a7738549eb274626b01e663bf30111994d91e2384ddbb0dc292c', NOW(), 'ACTIVE');

    INSERT INTO User (first_name,last_name,email,phone_number,user_type,city_id,password_hash,registration_date,account_status,birth_date )VALUES
    ('Ali', 'Rezaei', 'ali.rezaei.new@example.com', '9121000001', 'CUSTOMER', 1, SHA2('passAli123', 256), DATE_SUB(NOW(), INTERVAL 30 DAY), 'ACTIVE', '1990-05-15'),
    ('Zahra', 'Ahmadi', 'zahra.ahmadi.new@example.com', '9121000002', 'CUSTOMER', 2, SHA2('passZahra456', 256), DATE_SUB(NOW(), INTERVAL 28 DAY), 'ACTIVE', '1992-08-20'),
    ('Mohammad', 'Hosseini', 'mohammad.h.new@example.com', '9121000003', 'CUSTOMER', 3, SHA2('passMoh789', 256), DATE_SUB(NOW(), INTERVAL 25 DAY), 'ACTIVE', '1985-01-10'),
    ('Fatemeh', 'Karimi', 'fatemeh.k.new@example.com', '9121000004', 'CUSTOMER', 4, SHA2('passFatK101', 256), DATE_SUB(NOW(), INTERVAL 22 DAY), 'INACTIVE', '1998-12-05'),
    ('Hossein', 'Sadeghi', 'hossein.s.new@example.com', '9121000005', 'CUSTOMER', 5, SHA2('passHosS202', 256), DATE_SUB(NOW(), INTERVAL 20 DAY), 'ACTIVE', '1991-07-07'),
    ('Maryam', 'Moradi', 'maryam.m.new@example.com', '9121000006', 'CUSTOMER', 6, SHA2('passMarM303', 256), DATE_SUB(NOW(), INTERVAL 18 DAY), 'ACTIVE', '1993-03-25'),
    ('Reza', 'Jafari', 'reza.j.new@example.com', '9121000007', 'CUSTOMER', 7, SHA2('passRezJ404', 256), DATE_SUB(NOW(), INTERVAL 16 DAY), 'ACTIVE', '1980-11-30'),
    ('Sara', 'Kazemi', 'sara.k.new@example.com', '9121000008', 'CUSTOMER', 8, SHA2('passSarK505', 256), DATE_SUB(NOW(), INTERVAL 14 DAY), 'ACTIVE', '1997-09-12'),
    ('Mehdi', 'Asadi', 'mehdi.a.new@example.com', '9121000009', 'CUSTOMER', 9, SHA2('passMehA606', 256), DATE_SUB(NOW(), INTERVAL 12 DAY), 'ACTIVE', '1994-06-01'),
    ('Narges', 'Ghasemi', 'narges.gh.new@example.com', '9121000010', 'CUSTOMER', 10, SHA2('passNarG707', 256), DATE_SUB(NOW(), INTERVAL 10 DAY), 'ACTIVE', '1996-02-18'),
    ('Amir', 'Naderi', 'amir.naderi.new@example.com', '9121000011', 'CUSTOMER', 11, SHA2('passAmirN808', 256), DATE_SUB(NOW(), INTERVAL 40 DAY), 'ACTIVE', '1989-04-11'),
    ('Leila', 'Vakili', 'leila.vakili.new@example.com', '9121000012', 'CUSTOMER', 12, SHA2('passLeiV909', 256), DATE_SUB(NOW(), INTERVAL 38 DAY), 'ACTIVE', '1999-10-28'),
    ('Saeed', 'Taheri', 'saeed.taheri.new@example.com', '9121000013', 'CUSTOMER', 13, SHA2('passSaeT010', 256), DATE_SUB(NOW(), INTERVAL 35 DAY), 'ACTIVE', '1983-06-14'),
    ('Arezoo', 'Mohammadi', 'arezoo.m.new@example.com', '9121000014', 'CUSTOMER', 14, SHA2('passAreM111', 256), DATE_SUB(NOW(), INTERVAL 33 DAY), 'INACTIVE', '2001-03-03'),
    ('Peyman', 'Akbari', 'peyman.a.new@example.com', '9121000015', 'CUSTOMER', 15, SHA2('passPeyA212', 256), DATE_SUB(NOW(), INTERVAL 31 DAY), 'ACTIVE', '1990-08-22'),
    ('Roya', 'Sharifi', 'roya.s.new@example.com', '9121000016', 'CUSTOMER', 16, SHA2('passRoyS313', 256), DATE_SUB(NOW(), INTERVAL 29 DAY), 'ACTIVE', '1987-12-09'),
    ('Kianoosh', 'Yazdani', 'kianoosh.y.new@example.com', '9121000017', 'CUSTOMER', 17, SHA2('passKiaY414', 256), DATE_SUB(NOW(), INTERVAL 27 DAY), 'ACTIVE', '1995-05-02'),
    ('Negar', 'Bagheri', 'negar.b.new@example.com', '9121000018', 'CUSTOMER', 18, SHA2('passNegB515', 256), DATE_SUB(NOW(), INTERVAL 26 DAY), 'ACTIVE', '1992-11-17'),
    ('Farhad', 'Azizi', 'farhad.a.new@example.com', '9121000019', 'CUSTOMER', 19, SHA2('passFarA616', 256), DATE_SUB(NOW(), INTERVAL 24 DAY), 'ACTIVE', '1986-09-08'),
    ('Shabnam', 'Mansouri', 'shabnam.m.new@example.com', '9121000020', 'CUSTOMER', 20, SHA2('passShaM717', 256), DATE_SUB(NOW(), INTERVAL 23 DAY), 'ACTIVE', '1997-07-21'),
    ('Michael', 'Smithson', 'michael.smithson@example.com', '9301000001', 'CUSTOMER', 21, SHA2('mSmith88', 256), DATE_SUB(NOW(), INTERVAL 50 DAY), 'ACTIVE', '1988-04-10'),
    ('Sarah', 'Johnson', 'sarah.johns.new@example.com', '9301000002', 'CUSTOMER', 22, SHA2('sJohn93', 256), DATE_SUB(NOW(), INTERVAL 48 DAY), 'ACTIVE', '1993-09-05'),
    ('David', 'Williamson', 'david.williamson@example.com', '9301000003', 'CUSTOMER', 23, SHA2('dWill75', 256), DATE_SUB(NOW(), INTERVAL 45 DAY), 'ACTIVE', '1975-02-20'),
    ('Jennifer', 'Brownlee', 'jennifer.brownlee@example.com', '9301000004', 'CUSTOMER', 24, SHA2('jBrown96', 256), DATE_SUB(NOW(), INTERVAL 42 DAY), 'INACTIVE', '1996-11-15'),
    ('James', 'Jones Jr', 'james.jonesjr@example.com', '9301000005', 'CUSTOMER', 25, SHA2('jJones91', 256), DATE_SUB(NOW(), INTERVAL 40 DAY), 'ACTIVE', '1991-06-25'),
    ('Linda', 'Garcia', 'linda.garcia.new@example.com', '9301000006', 'CUSTOMER', 26, SHA2('lGar94', 256), DATE_SUB(NOW(), INTERVAL 38 DAY), 'ACTIVE', '1994-01-30'),
    ('Robert', 'Milligan', 'robert.milligan@example.com', '9301000007', 'CUSTOMER', 27, SHA2('rMill82', 256), DATE_SUB(NOW(), INTERVAL 36 DAY), 'ACTIVE', '1982-10-03'),
    ('Patricia', 'Davison', 'patricia.davison@example.com', '9301000008', 'CUSTOMER', 28, SHA2('pDavis98', 256), DATE_SUB(NOW(), INTERVAL 34 DAY), 'ACTIVE', '1998-07-19'),
    ('Christopher', 'Rodrigo', 'chris.rodrigo@example.com', '9301000009', 'CUSTOMER', 29, SHA2('cRod90', 256), DATE_SUB(NOW(), INTERVAL 32 DAY), 'ACTIVE', '1990-03-08'),
    ('Jessica', 'Martin', 'jessica.martin.new@example.com', '9301000010', 'CUSTOMER', 30, SHA2('jMar95', 256), DATE_SUB(NOW(), INTERVAL 30 DAY), 'ACTIVE', '1995-12-22'),
    ('Nima', 'Valipour', 'nima.valipour@example.com', '9901000001', 'ADMIN', 31, SHA2('nimaSup85', 256), DATE_SUB(NOW(), INTERVAL 60 DAY), 'ACTIVE', '1985-06-10'),
    ('Susan', 'Taylor', 'susan.taylor@example.com', '9901000002', 'ADMIN', 32, SHA2('susanSup90', 256), DATE_SUB(NOW(), INTERVAL 58 DAY), 'ACTIVE', '1990-11-05'),
    ('Kaveh', 'Afshar', 'kaveh.afshar@example.com', '9901000003', 'ADMIN', 33, SHA2('kavehSup93', 256), DATE_SUB(NOW(), INTERVAL 55 DAY), 'ACTIVE', '1993-01-20'),
    ('Emily', 'Clark', 'emily.clark@example.com', '9901000004', 'ADMIN', 34, SHA2('emilySup88', 256), DATE_SUB(NOW(), INTERVAL 52 DAY), 'ACTIVE', '1988-08-15'),
    ('Borzou', 'Arjmand', 'borzou.arjmand@example.com', '9901000005', 'ADMIN', 35, SHA2('borzouSup91', 256), DATE_SUB(NOW(), INTERVAL 50 DAY), 'ACTIVE', '1991-04-25'),
    ('Laura', 'Hill', 'laura.hill@example.com', '9901000006', 'ADMIN', 1, SHA2('lauraSup94', 256), DATE_SUB(NOW(), INTERVAL 48 DAY), 'ACTIVE', '1994-02-12'),
    ('Ramin', 'Farahani', 'ramin.farahani@example.com', '9901000007', 'ADMIN', 2, SHA2('raminSup89', 256), DATE_SUB(NOW(), INTERVAL 46 DAY), 'ACTIVE', '1989-09-01'),
    ('Megan', 'Scott', 'megan.scott@example.com', '9901000008', 'ADMIN', 3, SHA2('meganSup96', 256), DATE_SUB(NOW(), INTERVAL 44 DAY), 'ACTIVE', '1996-07-07'),
    ('Shayan', 'Kamali', 'shayan.kamali@example.com', '9901000009', 'ADMIN', 4, SHA2('shayanSup92', 256), DATE_SUB(NOW(), INTERVAL 42 DAY), 'ACTIVE', '1992-03-18'),
    ('Grace', 'Adams', 'grace.adams@example.com', '9901000010', 'ADMIN', 5, SHA2('graceSup87', 256), DATE_SUB(NOW(), INTERVAL 40 DAY), 'ACTIVE', '1987-10-30'),
    ('Olivia', 'Wilson', 'olivia.w.new@example.com', '9301000011', 'CUSTOMER', 39, SHA2('oliviaW97', 256), DATE_SUB(NOW(), INTERVAL 28 DAY), 'ACTIVE', '1997-04-03'),
    ('William', 'Moore', 'william.m.new@example.com', '9301000012', 'CUSTOMER', 40, SHA2('williamM84', 256), DATE_SUB(NOW(), INTERVAL 26 DAY), 'ACTIVE', '1984-10-17'),
    ('Sophia', 'Taylor', 'sophia.t.new@example.com', '9301000013', 'CUSTOMER', 41, SHA2('sophiaT92', 256), DATE_SUB(NOW(), INTERVAL 24 DAY), 'ACTIVE', '1992-05-28'),
    ('Daniel', 'Anderson', 'daniel.a.new@example.com', '9301000014', 'CUSTOMER', 42, SHA2('danielA89', 256), DATE_SUB(NOW(), INTERVAL 22 DAY), 'ACTIVE', '1989-12-01'),
    ('Ava', 'Thomas', 'ava.t.new@example.com', '9301000015', 'CUSTOMER', 43, SHA2('avaT99', 256), DATE_SUB(NOW(), INTERVAL 20 DAY), 'ACTIVE', '1999-08-11'),
    ('Bahram', 'Radan', 'bahram.radan.new@example.com', '9121000021', 'CUSTOMER', 44, SHA2('bahramR78', 256), DATE_SUB(NOW(), INTERVAL 19 DAY), 'ACTIVE', '1978-04-28'),
    ('Hediyeh', 'Tehranchi', 'hediyeh.t.new@example.com', '9121000022', 'CUSTOMER', 45, SHA2('hediyehT72', 256), DATE_SUB(NOW(), INTERVAL 17 DAY), 'ACTIVE', '1972-06-25'),
    ('Navid', 'Mohammadzadeh', 'navid.m.new@example.com', '9121000023', 'CUSTOMER', 46, SHA2('navidM86', 256), DATE_SUB(NOW(), INTERVAL 15 DAY), 'ACTIVE', '1986-04-06'),
    ('Taraneh', 'Alidoosti', 'taraneh.a.new@example.com', '9121000024', 'CUSTOMER', 47, SHA2('taranehA84', 256), DATE_SUB(NOW(), INTERVAL 13 DAY), 'ACTIVE', '1984-01-12'),
    ('Shahab', 'Hosseini', 'shahab.h.new2@example.com', '9121000025', 'CUSTOMER', 48, SHA2('shahabH74', 256), DATE_SUB(NOW(), INTERVAL 11 DAY), 'ACTIVE', '1974-02-03');
    

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
    ('plane', 40, 79, NOW(), DATE_ADD(NOW(), INTERVAL 5 HOUR), 210, 170, 10, 275, true, 'business'),
    ('plane', 1, 20, '2025-06-10 08:30:00', '2025-06-10 09:45:00', 180, 120, 21, 2500000, false, 'economy'),
    ('plane', 22, 5, '2025-06-10 12:00:00', '2025-06-10 13:15:00', 180, 150, 21, 2650000, true, 'economy'),   
    ('plane', 7, 30, '2025-06-12 14:00:00', '2025-06-12 15:10:00', 150, 50, 22, 3200000, false, 'business'),
    ('plane', 35, 2, '2025-06-15 09:00:00', '2025-06-15 10:20:00', 200, 180, 23, 1800000, true, 'economy'),
    ('plane', 10, 40, '2025-06-18 17:30:00', '2025-06-18 19:00:00', 120, 30, 24, 4500000, false, 'VIP'),
    ('plane', 45, 15, '2025-06-20 11:00:00', '2025-06-20 12:00:00', 160, 100, 25, 2200000, false, 'economy'),
    ('plane', 50, 3, '2025-07-01 06:00:00', '2025-07-01 08:15:00', 130, 130, 26, 3800000, true, 'business'),
    ('plane', 60, 12, '2025-07-05 21:00:00', '2025-07-05 22:50:00', 190, 88, 27, 2900000, false, 'economy'),
    ('plane', 18, 70, '2025-07-08 10:30:00', '2025-07-08 11:45:00', 170, 160, 21, 2700000, false, 'economy'),
    ('plane', 75, 4, '2025-07-08 14:00:00', '2025-07-08 15:15:00', 170, 140, 21, 2850000, true, 'economy'),

    ('train', 3, 33, '2025-06-10 22:00:00', '2025-06-11 06:30:00', 300, 250, 11, 800000, false, 'economy'),
    ('train', 38, 9, '2025-06-13 23:30:00', '2025-06-14 07:00:00', 300, 180, 11, 950000, true, 'business'),
    ('train', 11, 42, '2025-06-14 15:00:00', '2025-06-14 21:00:00', 240, 200, 12, 650000, false, 'economy'),
    ('train', 48, 6, '2025-06-16 08:00:00', '2025-06-16 12:30:00', 180, 150, 13, 1200000, true, 'VIP'),
    ('train', 21, 52, '2025-06-19 18:00:00', '2025-06-20 05:00:00', 200, 100, 14, 750000, false, 'economy'),
    ('train', 58, 14, '2025-06-22 13:15:00', '2025-06-23 01:45:00', 220, 210, 15, 900000, true, 'business'),
    ('train', 25, 62, '2025-07-02 07:00:00', '2025-07-02 11:00:00', 280, 270, 11, 550000, false, 'economy'),
    ('train', 68, 2, '2025-07-02 13:00:00', '2025-07-02 17:00:00', 280, 250, 11, 600000, true, 'economy'),
    ('train', 31, 72, '2025-07-10 10:00:00', '2025-07-10 20:30:00', 150, 145, 12, 1100000, false, 'business'),
    ('train', 78, 34, '2025-07-11 09:00:00', '2025-07-11 19:30:00', 150, 130, 12, 1150000, true, 'business'),

    ('bus', 4, 80, '2025-06-09 23:00:00', '2025-06-10 05:00:00', 44, 30, 1, 350000, false, 'VIP'),
    ('bus', 85, 10, '2025-06-11 14:30:00', '2025-06-11 20:30:00', 40, 35, 1, 320000, true, 'VIP'),
    ('bus', 12, 90, '2025-06-13 09:00:00', '2025-06-13 21:00:00', 44, 40, 2, 550000, false, 'VIP'),
    ('bus', 95, 16, '2025-06-14 07:00:00', '2025-06-14 10:00:00', 25, 15, 3, 150000, true, 'economy'),
    ('bus', 20, 100, '2025-06-17 22:30:00', '2025-06-18 12:00:00', 40, 22, 4, 600000, false, 'VIP'),
    ('bus', 105, 26, '2025-06-21 10:00:00', '2025-06-21 23:00:00', 25, 20, 5, 480000, true, 'economy'),
    ('bus', 30, 110, '2025-06-25 13:00:00', '2025-06-25 23:59:00', 44, 44, 6, 700000, false, 'VIP'),
    ('bus', 115, 32, '2025-07-03 11:00:00', '2025-07-03 19:00:00', 40, 30, 1, 400000, true, 'VIP'),
    ('bus', 36, 120, '2025-07-04 09:30:00', '2025-07-04 17:30:00', 40, 33, 1, 380000, false, 'VIP'),
    ('bus', 125, 39, '2025-07-06 08:00:00', '2025-07-06 22:00:00', 25, 10, 2, 650000, true, 'economy'),

    ('plane', 41, 81, '2025-07-10 10:00:00', '2025-07-10 11:15:00', 150, 140, 22, 3100000, false, 'business'),
    ('train', 88, 43, '2025-07-12 16:30:00', '2025-07-12 20:00:00', 200, 190, 13, 1100000, true, 'VIP'),
    ('bus', 13, 92, '2025-07-15 08:00:00', '2025-07-15 18:30:00', 40, 38, 2, 500000, false, 'VIP'),
    ('plane', 1, 98, '2025-05-01 13:00:00', '2025-05-01 14:20:00', 180, 0, 23, 2750000, true, 'economy'),
    ('train', 3, 102, '2025-04-20 09:15:00', '2025-04-20 22:00:00', 250, 10, 11, 980000, false, 'business'),
    ('bus', 4, 108, '2025-05-10 21:30:00', '2025-05-11 06:00:00', 44, 5, 1, 420000, true, 'VIP'), 
    ('plane', 6, 112, '2025-07-25 15:00:00', '2025-07-25 16:00:00', 160, 150, 24, 1900000, false, 'economy'),
    ('train', 9, 118, '2025-07-28 11:30:00', '2025-07-28 18:00:00', 180, 175, 12, 880000, true, 'business'),
    ('bus', 15, 122, '2025-07-30 06:00:00', '2025-07-30 12:30:00', 25, 23, 3, 320000, false, 'economy'),
    ('plane', 19, 128, '2025-08-01 18:00:00', '2025-08-01 19:45:00', 120, 110, 25, 4000000, true, 'VIP'),

    ('train', 24, 130, '2025-08-03 14:00:00', '2025-08-03 23:59:00', 220, 200, 13, 1500000, false, 'VIP'),
    ('bus', 29, 132, '2025-08-05 12:30:00', '2025-08-05 16:00:00', 44, 40, 4, 200000, true, 'economy'),
    ('plane', 34, 135, '2025-08-07 07:45:00', '2025-08-07 09:00:00', 180, 170, 26, 2950000, false, 'business'),
    ('train', 37, 138, '2025-08-10 00:30:00', '2025-08-10 08:00:00', 300, 280, 14, 850000, true, 'economy'),
    ('bus', 43, 137, '2025-08-12 16:00:00', '2025-08-13 02:00:00', 40, 35, 5, 580000, false, 'VIP'),
    ('plane', 47, 136, '2025-08-14 11:15:00', '2025-08-14 12:20:00', 150, 140, 27, 2400000, true, 'economy'),
    ('train', 51, 134, '2025-08-16 19:00:00', '2025-08-17 01:00:00', 240, 230, 15, 720000, false, 'business'),
    ('bus', 55, 131, '2025-08-18 23:50:00', '2025-08-19 11:00:00', 44, 41, 6, 680000, true, 'VIP'),
    ('plane', 59, 129, '2025-08-20 17:00:00', '2025-08-20 18:30:00', 120, 115, 21, 4200000, false, 'VIP');

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


    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_1 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_1, 'Mahan Air', 'economy', 0, CONCAT('W5-', FLOOR(1100 + RAND() * 100)), 'IKA', 'MHD', '{"wifi": true, "meal": "snack", "entertainment_system": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_2 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_2, 'Iran Air', 'business', 1, CONCAT('IR-', FLOOR(400 + RAND() * 100)), 'THR', 'SYZ', '{"wifi": true, "meal": "full", "lounge_access": true, "extra_legroom": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_3 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_3, 'Caspian Airlines', 'economy', 0, CONCAT('IV-', FLOOR(6200 + RAND() * 100)), 'IFN', 'KIH', '{"meal": "snack"}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_4 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_4, 'Zagros Airlines', 'economy', 0, CONCAT('ZV-', FLOOR(3000 + RAND() * 100)), 'AWZ', 'MHD', '{"wifi": false, "meal": "sandwich"}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_5 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_5, 'Kish Air', 'business', 0, CONCAT('Y9-', FLOOR(7000 + RAND() * 100)), 'KIH', 'THR', '{"meal": "full", "priority_boarding": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_6 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_6, 'Aseman Airlines', 'economy', 1, CONCAT('EP-', FLOOR(800 + RAND() * 100)), 'SYZ', 'TBZ', '{"meal": "snack", "usb_port": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_7 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_7, 'Taban Air', 'economy', 0, CONCAT('HH-', FLOOR(2600 + RAND() * 100)), 'RAS', 'IFN', '{"meal": "none"}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_8 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_8, 'Sepehran Airlines', 'first_class', 0, CONCAT('SP-', FLOOR(3300 + RAND() * 100)), 'MHD', 'IKA', '{"wifi": true, "meal": "premium", "lie_flat_seat": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_9 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_9, 'Qeshm Air', 'economy', 0, CONCAT('QB-', FLOOR(1200 + RAND() * 100)), 'GSM', 'THR', '{"meal": "snack"}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_10 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_10, 'Pars Air', 'business', 0, CONCAT('PR-', FLOOR(7700 + RAND() * 100)), 'PGU', 'SYZ', '{"meal": "full", "extra_baggage": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_11 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_11, 'Varesh Airlines', 'economy', 0, CONCAT('VR-', FLOOR(5300 + RAND() * 100)), 'SRY', 'MHD', '{"meal": "sandwich"}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_12 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_12, 'FlyPersia', 'economy', 1, CONCAT('FP-', FLOOR(4200 + RAND() * 100)), 'THR', 'BND', '{"meal": "snack"}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_13 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_13, 'Karun Airlines', 'economy', 0, CONCAT('NV-', FLOOR(2800 + RAND() * 100)), 'AWZ', 'IFN', '{"meal": "snack"}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_14 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_14, 'ATA Airlines', 'business', 0, CONCAT('I3-', FLOOR(5500 + RAND() * 100)), 'TBZ', 'IST', '{"meal": "full", "lounge_access": true}'); -- پرواز خارجی نمونه

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('flight');
    SET @last_vehicle_id_flight_15 = LAST_INSERT_ID();
    INSERT INTO FlightDetail (flight_id, airline_name, flight_class, stops, flight_number, origin_airport, destination_airport, facilities)
    VALUES (@last_vehicle_id_flight_15, 'Iran Airtour', 'economy', 0, CONCAT('B9-', FLOOR(900 + RAND() * 100)), 'MHD', 'KIH', '{"meal": "snack"}');


    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_1 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_1, '5', true, '{"wifi": true, "meal_service": "full", "air_conditioning": true, "power_outlets": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_2 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_2, '4', false, '{"wifi": true, "meal_service": "snack", "air_conditioning": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_3 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_3, '3', false, '{"air_conditioning": true, "reading_light": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_4 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_4, '5', true, '{"wifi": true, "entertainment_system": true, "restaurant_car": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_5 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_5, '4', true, '{"meal_service": "full", "power_outlets": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_6 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_6, '4', false, '{"wifi": false, "cafe_car": true, "air_conditioning": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_7 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_7, '5', true, '{"bedding_provided": true, "onboard_staff": true, "secure_storage": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_8 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_8, '3', false, '{"wc_available": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_9 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_9, '4', true, '{"scenic_windows": true, "meal_service": "optional"}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_10 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_10, '5', false, '{"family_compartment": true, "playground_area": false}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_11 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_11, '4', false, '{"pet_friendly_cabin": false, "bicycle_storage": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_12 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_12, '3', true, '{"basic_amenities": true}');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('train');
    SET @last_vehicle_id_train_13 = LAST_INSERT_ID();
    INSERT INTO TrainDetail (train_id, train_rating, private_cabin, facilities)
    VALUES (@last_vehicle_id_train_13, '5', true, '{"luxury_suite": true, "private_bathroom": true, "butler_service": false}');


    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_1 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_1, 'Iran Peyma', 'VIP', '{"wifi": true, "usb_charger": true, "reclining_seats": true, "monitor": true}', '1+2');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_2 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_2, 'Hamsafar', 'regular', '{"air_conditioning": true, "reading_light": true}', '2+2');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_3 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_3, 'Seirosafar', 'sleeper', '{"wifi": false, "blanket_pillow": true, "curtains": true}', '1+2');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_4 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_4, 'Royal Safar', 'VIP', '{"wifi": true, "snack_box": true, "leg_rest": true}', '1+2');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_5 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_5, 'Giti Peyma', 'regular', '{"audio_system": true}', '2+2');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_6 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_6, 'Tak Safar Iranian', 'VIP', '{"wifi": true, "water_bottle": true, "charging_port_per_seat": true}', '1+2');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_7 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_7, 'Loux Express', 'sleeper', '{"privacy_curtain": true, "adjustable_bed_seat": true}', '1+2');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_8 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_8, 'Chaboksavaran', 'regular', '{"overhead_storage": true}', '2+2');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_9 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_9, 'Asia Safar', 'VIP', '{"wifi": true, "personal_monitor": true, "comfortable_headrest": true}', '1+2');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_10 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_10, 'Payaneh Ha', 'regular', '{"standard_seating": true}', '2+2');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_11 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_11, 'TBT', 'VIP', '{"extra_wide_seats": true, "onboard_wc": false}', '1+2');

    INSERT INTO VehicleDetail (vehicle_type) VALUES ('bus');
    SET @last_vehicle_id_bus_12 = LAST_INSERT_ID();
    INSERT INTO BusDetail (bus_id, bus_company, bus_type, facilities, seat_arrangement)
    VALUES (@last_vehicle_id_bus_12, 'Adl Shargh', 'sleeper', '{"fully_reclining_seats": true, "meal_service_optional": true}', '1+2');

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number)
    VALUES
    (1, 1, 10), (2, 2, 15), (3, 3, 5), (4, 4, 20), (5, 5, 30), (6, 6, 8), (7, 7, 18), (8, 8, 25), (9, 9, 35), (10, 10, 12);




    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 7);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 8);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 9);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 10);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 11);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 12);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 13);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 14);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 15);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 16);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 17);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 18);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 19);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 20);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 21);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 22);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 23);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 24);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 25);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 26);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 27);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 28);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 29);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 30);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 31);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 32);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 33);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 34);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 35);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 36);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 37);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 38);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 39);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 40);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 41);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 42);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 43);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 44);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 45);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 46);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 47);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 48);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 49);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 50);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 51);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 52);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 53);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 54);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 55);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 56);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 57);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 58);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 59);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 60);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 61);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 62);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 63);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 64);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 65);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 66);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 67);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 68);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 69);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 70);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 71);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 72);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 73);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 74);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 75);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 76);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 77);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 78);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 79);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 80);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 81);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 82);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 83);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 84);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 85);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 86);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 87);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 88);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 89);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 90);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 91);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 92);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 93);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 94);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 95);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 96);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 97);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 98);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 99);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 100);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 101);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 102);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 103);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 104);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 105);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 106);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 107);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 108);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 109);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 110);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 111);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 112);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 113);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 114);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 115);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 116);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 117);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 118);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 119);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 120);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 121);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 122);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 123);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 124);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 125);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 126);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 127);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 128);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 129);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 130);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 131);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 132);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 133);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 134);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 135);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 136);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 137);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 138);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 139);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 140);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 141);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 142);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 143);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 144);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 145);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 146);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 147);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 148);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (11, 11, 149);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 7);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 8);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 9);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 10);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 11);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 12);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 13);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 14);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 15);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (12, 12, 16);

    

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (13, 13, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (13, 13, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (13, 13, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (13, 13, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (13, 13, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (13, 13, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (13, 13, 7);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (13, 13, 8);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (13, 13, 9);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 7);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 8);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 9);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 10);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 11);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 12);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 13);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 14);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 15);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 16);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 17);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (14, 14, 18);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (15, 15, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (15, 15, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (15, 15, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (15, 15, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (15, 15, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (15, 15, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (15, 15, 7);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (15, 15, 8);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (21, 26, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (21, 26, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (21, 26, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (21, 26, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (21, 26, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (21, 26, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (21, 26, 7);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (22, 27, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (22, 27, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (22, 27, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (22, 27, 4);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (23, 28, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (23, 28, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (23, 28, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (23, 28, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (23, 28, 5);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 7);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 8);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 9);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 10);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 11);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 12);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 13);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 14);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 15);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (24, 29, 16);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 7);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 8);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 9);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 10);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 11);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 12);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 13);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (25, 30, 14);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (31, 39, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (31, 39, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (31, 39, 3);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (32, 40, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (32, 40, 2);


    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (33, 41, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (33, 41, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (33, 41, 3);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (34, 42, 1);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (35, 43, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (35, 43, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (35, 43, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (35, 43, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (35, 43, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (35, 43, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (35, 43, 7);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 7);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 8);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 9);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 10);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 11);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 12);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 13);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 14);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 15);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 16);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (44, 16, 17);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (45, 31, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (45, 31, 2);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (46, 44, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (46, 44, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (46, 44, 3);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (48, 32, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (48, 32, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (48, 32, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (48, 32, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (48, 32, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (48, 32, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (48, 32, 7);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (48, 32, 8);

    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (52, 39, 1);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (52, 39, 2);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (52, 39, 3);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (52, 39, 4);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (52, 39, 5);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (52, 39, 6);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (52, 39, 7);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (52, 39, 8);
    INSERT INTO Ticket (travel_id, vehicle_id, seat_number) VALUES (52, 39, 9);


    

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

    INSERT INTO Reservation (user_id, ticket_id, status, reservation_time, expiration_time) VALUES
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 11, 'paid', '2025-06-01 08:00:00', '2025-06-01 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 12, 'paid', '2025-06-01 08:05:00', '2025-06-01 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 13, 'paid', '2025-06-01 08:10:00', '2025-06-01 08:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 14, 'paid', '2025-06-01 08:15:00', '2025-06-01 08:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 15, 'paid', '2025-06-01 08:20:00', '2025-06-01 08:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 16, 'paid', '2025-06-01 08:25:00', '2025-06-01 08:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 17, 'paid', '2025-06-01 08:30:00', '2025-06-01 08:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 18, 'paid', '2025-06-01 08:35:00', '2025-06-01 08:50:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 19, 'paid', '2025-06-01 08:40:00', '2025-06-01 08:55:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 20, 'paid', '2025-06-01 08:45:00', '2025-06-01 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 21, 'paid', '2025-06-01 08:50:00', '2025-06-01 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 22, 'paid', '2025-06-01 08:55:00', '2025-06-01 09:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 23, 'paid', '2025-06-01 09:00:00', '2025-06-01 09:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 24, 'paid', '2025-06-01 09:05:00', '2025-06-01 09:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 25, 'paid', '2025-06-01 09:10:00', '2025-06-01 09:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 26, 'paid', '2025-06-01 09:15:00', '2025-06-01 09:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 27, 'paid', '2025-06-01 09:20:00', '2025-06-01 09:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 28, 'paid', '2025-06-01 09:25:00', '2025-06-01 09:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 29, 'paid', '2025-06-01 09:30:00', '2025-06-01 09:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 30, 'paid', '2025-06-01 09:35:00', '2025-06-01 09:50:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 31, 'paid', '2025-06-01 09:40:00', '2025-06-01 09:55:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 32, 'paid', '2025-06-01 09:45:00', '2025-06-01 10:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 33, 'paid', '2025-06-01 09:50:00', '2025-06-01 10:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 34, 'paid', '2025-06-01 09:55:00', '2025-06-01 10:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 35, 'paid', '2025-06-01 10:00:00', '2025-06-01 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 36, 'paid', '2025-06-01 10:05:00', '2025-06-01 10:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 37, 'paid', '2025-06-01 10:10:00', '2025-06-01 10:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 38, 'paid', '2025-06-01 10:15:00', '2025-06-01 10:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 39, 'paid', '2025-06-01 10:20:00', '2025-06-01 10:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 40, 'paid', '2025-06-01 10:25:00', '2025-06-01 10:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 41, 'reserved', '2025-06-02 10:00:00', '2025-06-09 10:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 42, 'reserved', '2025-06-02 10:05:00', '2025-06-09 10:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 43, 'reserved', '2025-06-02 10:10:00', '2025-06-09 10:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 44, 'reserved', '2025-06-02 10:15:00', '2025-06-09 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 45, 'reserved', '2025-06-02 10:20:00', '2025-06-09 10:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 46, 'reserved', '2025-06-02 10:25:00', '2025-06-09 10:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 47, 'reserved', '2025-06-02 10:30:00', '2025-06-09 10:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 48, 'reserved', '2025-06-02 10:35:00', '2025-06-09 10:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 49, 'reserved', '2025-06-02 10:40:00', '2025-06-09 10:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 50, 'reserved', '2025-06-02 10:45:00', '2025-06-09 10:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 51, 'reserved', '2025-06-02 10:50:00', '2025-06-09 10:50:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 52, 'reserved', '2025-06-02 10:55:00', '2025-06-09 10:55:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 53, 'reserved', '2025-06-02 11:00:00', '2025-06-09 11:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 54, 'reserved', '2025-06-02 11:05:00', '2025-06-09 11:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 55, 'reserved', '2025-06-02 11:10:00', '2025-06-09 11:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 56, 'reserved', '2025-06-02 11:15:00', '2025-06-09 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 57, 'reserved', '2025-06-02 11:20:00', '2025-06-09 11:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 58, 'reserved', '2025-06-02 11:25:00', '2025-06-09 11:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 59, 'reserved', '2025-06-02 11:30:00', '2025-06-09 11:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 60, 'reserved', '2025-06-02 11:35:00', '2025-06-09 11:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 61, 'canceled', '2025-05-15 09:00:00', '2025-05-15 09:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 62, 'canceled', '2025-05-15 09:05:00', '2025-05-15 09:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 63, 'canceled', '2025-05-15 09:10:00', '2025-05-15 09:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 64, 'canceled', '2025-05-15 09:15:00', '2025-05-15 09:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 65, 'canceled', '2025-05-15 09:20:00', '2025-05-15 09:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 66, 'canceled', '2025-05-15 09:25:00', '2025-05-15 09:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 67, 'canceled', '2025-05-15 09:30:00', '2025-05-15 09:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 68, 'canceled', '2025-05-15 09:35:00', '2025-05-15 09:50:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 69, 'canceled', '2025-05-15 09:40:00', '2025-05-15 09:55:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 70, 'canceled', '2025-05-15 09:45:00', '2025-05-15 10:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 71, 'paid', '2025-06-03 08:00:00', '2025-06-03 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 72, 'paid', '2025-06-03 08:05:00', '2025-06-03 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 73, 'paid', '2025-06-03 08:10:00', '2025-06-03 08:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 74, 'paid', '2025-06-03 08:15:00', '2025-06-03 08:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 75, 'paid', '2025-06-03 08:20:00', '2025-06-03 08:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 76, 'paid', '2025-06-03 08:25:00', '2025-06-03 08:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 77, 'paid', '2025-06-03 08:30:00', '2025-06-03 08:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 78, 'paid', '2025-06-03 08:35:00', '2025-06-03 08:50:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 79, 'paid', '2025-06-03 08:40:00', '2025-06-03 08:55:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 80, 'paid', '2025-06-03 08:45:00', '2025-06-03 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 81, 'reserved', '2025-06-04 10:00:00', '2025-06-11 10:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 82, 'reserved', '2025-06-04 10:05:00', '2025-06-11 10:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 83, 'reserved', '2025-06-04 10:10:00', '2025-06-11 10:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 84, 'reserved', '2025-06-04 10:15:00', '2025-06-11 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 85, 'reserved', '2025-06-04 10:20:00', '2025-06-11 10:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 86, 'reserved', '2025-06-04 10:25:00', '2025-06-11 10:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 87, 'reserved', '2025-06-04 10:30:00', '2025-06-11 10:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 88, 'reserved', '2025-06-04 10:35:00', '2025-06-11 10:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 89, 'reserved', '2025-06-04 10:40:00', '2025-06-11 10:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 90, 'reserved', '2025-06-04 10:45:00', '2025-06-11 10:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 91, 'canceled', '2025-05-16 09:00:00', '2025-05-16 09:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 92, 'canceled', '2025-05-16 09:05:00', '2025-05-16 09:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 93, 'canceled', '2025-05-16 09:10:00', '2025-05-16 09:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 94, 'canceled', '2025-05-16 09:15:00', '2025-05-16 09:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 95, 'canceled', '2025-05-16 09:20:00', '2025-05-16 09:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 96, 'canceled', '2025-05-16 09:25:00', '2025-05-16 09:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 97, 'canceled', '2025-05-16 09:30:00', '2025-05-16 09:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 98, 'canceled', '2025-05-16 09:35:00', '2025-05-16 09:50:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 99, 'canceled', '2025-05-16 09:40:00', '2025-05-16 09:55:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 100, 'canceled', '2025-05-16 09:45:00', '2025-05-16 10:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 101, 'paid', '2025-06-05 08:00:00', '2025-06-05 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 102, 'paid', '2025-06-05 08:05:00', '2025-06-05 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 103, 'paid', '2025-06-05 08:10:00', '2025-06-05 08:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 104, 'paid', '2025-06-05 08:15:00', '2025-06-05 08:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 105, 'paid', '2025-06-05 08:20:00', '2025-06-05 08:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 106, 'paid', '2025-06-05 08:25:00', '2025-06-05 08:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 107, 'paid', '2025-06-05 08:30:00', '2025-06-05 08:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 108, 'paid', '2025-06-05 08:35:00', '2025-06-05 08:50:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 109, 'paid', '2025-06-05 08:40:00', '2025-06-05 08:55:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 110, 'paid', '2025-06-05 08:45:00', '2025-06-05 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 111, 'reserved', '2025-06-06 10:00:00', '2025-06-13 10:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 112, 'reserved', '2025-06-06 10:05:00', '2025-06-13 10:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 113, 'reserved', '2025-06-06 10:10:00', '2025-06-13 10:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 114, 'reserved', '2025-06-06 10:15:00', '2025-06-13 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 115, 'reserved', '2025-06-06 10:20:00', '2025-06-13 10:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 116, 'reserved', '2025-06-06 10:25:00', '2025-06-13 10:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 117, 'reserved', '2025-06-06 10:30:00', '2025-06-13 10:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 118, 'reserved', '2025-06-06 10:35:00', '2025-06-13 10:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 119, 'reserved', '2025-06-06 10:40:00', '2025-06-13 10:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 120, 'reserved', '2025-06-06 10:45:00', '2025-06-13 10:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 121, 'canceled', '2025-05-17 09:00:00', '2025-05-17 09:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 122, 'canceled', '2025-05-17 09:05:00', '2025-05-17 09:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 123, 'canceled', '2025-05-17 09:10:00', '2025-05-17 09:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 124, 'canceled', '2025-05-17 09:15:00', '2025-05-17 09:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 125, 'canceled', '2025-05-17 09:20:00', '2025-05-17 09:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 126, 'canceled', '2025-05-17 09:25:00', '2025-05-17 09:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 127, 'canceled', '2025-05-17 09:30:00', '2025-05-17 09:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 128, 'canceled', '2025-05-17 09:35:00', '2025-05-17 09:50:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 129, 'canceled', '2025-05-17 09:40:00', '2025-05-17 09:55:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 130, 'canceled', '2025-05-17 09:45:00', '2025-05-17 10:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 131, 'paid', '2025-06-07 08:00:00', '2025-06-07 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 132, 'paid', '2025-06-07 08:05:00', '2025-06-07 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 133, 'paid', '2025-06-07 08:10:00', '2025-06-07 08:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 134, 'paid', '2025-06-07 08:15:00', '2025-06-07 08:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 135, 'paid', '2025-06-07 08:20:00', '2025-06-07 08:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 136, 'paid', '2025-06-07 08:25:00', '2025-06-07 08:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 137, 'paid', '2025-06-07 08:30:00', '2025-06-07 08:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 138, 'paid', '2025-06-07 08:35:00', '2025-06-07 08:50:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 139, 'paid', '2025-06-07 08:40:00', '2025-06-07 08:55:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 140, 'paid', '2025-06-07 08:45:00', '2025-06-07 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 141, 'reserved', '2025-06-08 10:00:00', '2025-06-15 10:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 142, 'reserved', '2025-06-08 10:05:00', '2025-06-15 10:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 143, 'reserved', '2025-06-08 10:10:00', '2025-06-15 10:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 144, 'reserved', '2025-06-08 10:15:00', '2025-06-15 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 145, 'reserved', '2025-06-08 10:20:00', '2025-06-15 10:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 146, 'reserved', '2025-06-08 10:25:00', '2025-06-15 10:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 147, 'reserved', '2025-06-08 10:30:00', '2025-06-15 10:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 148, 'reserved', '2025-06-08 10:35:00', '2025-06-15 10:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 149, 'reserved', '2025-06-08 10:40:00', '2025-06-15 10:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 150, 'reserved', '2025-06-08 10:45:00', '2025-06-15 10:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 151, 'canceled', '2025-05-18 09:00:00', '2025-05-18 09:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 152, 'canceled', '2025-05-18 09:05:00', '2025-05-18 09:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 153, 'canceled', '2025-05-18 09:10:00', '2025-05-18 09:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 154, 'canceled', '2025-05-18 09:15:00', '2025-05-18 09:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 155, 'canceled', '2025-05-18 09:20:00', '2025-05-18 09:35:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 156, 'canceled', '2025-05-18 09:25:00', '2025-05-18 09:40:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 157, 'canceled', '2025-05-18 09:30:00', '2025-05-18 09:45:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 158, 'canceled', '2025-05-18 09:35:00', '2025-05-18 09:50:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 159, 'canceled', '2025-05-18 09:40:00', '2025-05-18 09:55:00');


    INSERT INTO Reservation (user_id, ticket_id, status, reservation_time, expiration_time) VALUES
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 160, 'paid', '2025-06-10 08:00:00', '2025-06-10 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 161, 'paid', '2025-06-10 08:05:00', '2025-06-10 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 162, 'paid', '2025-06-10 08:10:00', '2025-06-10 08:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 163, 'paid', '2025-06-10 08:15:00', '2025-06-10 08:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 164, 'reserved', '2025-06-11 09:00:00', '2025-06-18 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 165, 'reserved', '2025-06-11 09:05:00', '2025-06-18 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 166, 'reserved', '2025-06-11 09:10:00', '2025-06-18 09:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 167, 'reserved', '2025-06-11 09:15:00', '2025-06-18 09:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 168, 'canceled', '2025-05-20 10:00:00', '2025-05-20 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 169, 'canceled', '2025-05-20 10:05:00', '2025-05-20 10:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 170, 'canceled', '2025-05-20 10:10:00', '2025-05-20 10:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 171, 'paid', '2025-06-12 11:00:00', '2025-06-12 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 172, 'paid', '2025-06-12 11:05:00', '2025-06-12 11:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 173, 'reserved', '2025-06-13 12:00:00', '2025-06-20 12:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 174, 'canceled', '2025-05-21 13:00:00', '2025-05-21 13:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 175, 'paid', '2025-06-14 14:00:00', '2025-06-14 14:15:00');
   
    INSERT INTO Reservation (user_id, ticket_id, status, reservation_time, expiration_time) VALUES
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 176, 'paid', '2025-06-15 08:00:00', '2025-06-15 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 177, 'paid', '2025-06-15 08:05:00', '2025-06-15 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 178, 'reserved', '2025-06-16 09:00:00', '2025-06-23 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 179, 'reserved', '2025-06-16 09:05:00', '2025-06-23 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 180, 'canceled', '2025-05-22 10:00:00', '2025-05-22 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 181, 'paid', '2025-06-17 11:00:00', '2025-06-17 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 182, 'reserved', '2025-06-18 12:00:00', '2025-06-25 12:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 183, 'canceled', '2025-05-23 13:00:00', '2025-05-23 13:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 184, 'paid', '2025-06-19 14:00:00', '2025-06-19 14:15:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 185, 'paid', '2025-06-20 08:00:00', '2025-06-20 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 186, 'paid', '2025-06-20 08:05:00', '2025-06-20 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 187, 'paid', '2025-06-20 08:10:00', '2025-06-20 08:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 188, 'paid', '2025-06-20 08:15:00', '2025-06-20 08:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 189, 'reserved', '2025-06-21 09:00:00', '2025-06-28 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 190, 'reserved', '2025-06-21 09:05:00', '2025-06-28 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 191, 'reserved', '2025-06-21 09:10:00', '2025-06-28 09:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 192, 'reserved', '2025-06-21 09:15:00', '2025-06-28 09:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 193, 'canceled', '2025-05-24 10:00:00', '2025-05-24 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 194, 'canceled', '2025-05-24 10:05:00', '2025-05-24 10:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 195, 'canceled', '2025-05-24 10:10:00', '2025-05-24 10:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 196, 'paid', '2025-06-22 11:00:00', '2025-06-22 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 197, 'paid', '2025-06-22 11:05:00', '2025-06-22 11:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 198, 'reserved', '2025-06-23 12:00:00', '2025-06-30 12:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 199, 'canceled', '2025-05-25 13:00:00', '2025-05-25 13:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 200, 'paid', '2025-06-24 14:00:00', '2025-06-24 14:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 201, 'paid', '2025-06-24 14:05:00', '2025-06-24 14:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 202, 'reserved', '2025-06-25 15:00:00', '2025-07-02 15:00:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 203, 'paid', '2025-06-26 08:00:00', '2025-06-26 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 204, 'paid', '2025-06-26 08:05:00', '2025-06-26 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 205, 'reserved', '2025-06-27 09:00:00', '2025-07-04 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 206, 'reserved', '2025-06-27 09:05:00', '2025-07-04 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 207, 'canceled', '2025-05-26 10:00:00', '2025-05-26 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 208, 'paid', '2025-06-28 11:00:00', '2025-06-28 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 209, 'reserved', '2025-06-29 12:00:00', '2025-07-06 12:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 210, 'canceled', '2025-05-27 13:00:00', '2025-05-27 13:15:00');



    INSERT INTO Reservation (user_id, ticket_id, status, reservation_time, expiration_time) VALUES
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 211, 'paid', '2025-07-01 08:00:00', '2025-07-01 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 212, 'paid', '2025-07-01 08:05:00', '2025-07-01 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 213, 'reserved', '2025-07-02 09:00:00', '2025-07-09 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 214, 'reserved', '2025-07-02 09:05:00', '2025-07-09 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 215, 'canceled', '2025-06-10 10:00:00', '2025-06-10 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 216, 'paid', '2025-07-03 11:00:00', '2025-07-03 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 217, 'reserved', '2025-07-04 12:00:00', '2025-07-11 12:00:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 218, 'paid', '2025-07-05 08:00:00', '2025-07-05 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 219, 'paid', '2025-07-05 08:05:00', '2025-07-05 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 220, 'reserved', '2025-07-06 09:00:00', '2025-07-13 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 221, 'canceled', '2025-06-11 10:00:00', '2025-06-11 10:15:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 222, 'paid', '2025-07-07 08:00:00', '2025-07-07 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 223, 'reserved', '2025-07-08 09:00:00', '2025-07-15 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 224, 'reserved', '2025-07-08 09:05:00', '2025-07-15 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 225, 'canceled', '2025-06-12 10:00:00', '2025-06-12 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 226, 'paid', '2025-07-09 11:00:00', '2025-07-09 11:15:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 227, 'paid', '2025-07-10 08:00:00', '2025-07-10 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 228, 'paid', '2025-07-10 08:05:00', '2025-07-10 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 229, 'paid', '2025-07-10 08:10:00', '2025-07-10 08:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 230, 'paid', '2025-07-10 08:15:00', '2025-07-10 08:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 231, 'reserved', '2025-07-11 09:00:00', '2025-07-18 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 232, 'reserved', '2025-07-11 09:05:00', '2025-07-18 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 233, 'reserved', '2025-07-11 09:10:00', '2025-07-18 09:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 234, 'reserved', '2025-07-11 09:15:00', '2025-07-18 09:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 235, 'canceled', '2025-06-13 10:00:00', '2025-06-13 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 236, 'canceled', '2025-06-13 10:05:00', '2025-06-13 10:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 237, 'canceled', '2025-06-13 10:10:00', '2025-06-13 10:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 238, 'paid', '2025-07-12 11:00:00', '2025-07-12 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 239, 'paid', '2025-07-12 11:05:00', '2025-07-12 11:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 240, 'reserved', '2025-07-13 12:00:00', '2025-07-20 12:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 241, 'canceled', '2025-06-14 13:00:00', '2025-06-14 13:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 242, 'paid', '2025-07-14 14:00:00', '2025-07-14 14:15:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 243, 'paid', '2025-07-15 08:00:00', '2025-07-15 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 244, 'paid', '2025-07-15 08:05:00', '2025-07-15 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 245, 'paid', '2025-07-15 08:10:00', '2025-07-15 08:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 246, 'reserved', '2025-07-16 09:00:00', '2025-07-23 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 247, 'reserved', '2025-07-16 09:05:00', '2025-07-23 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 248, 'reserved', '2025-07-16 09:10:00', '2025-07-23 09:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 249, 'canceled', '2025-06-15 10:00:00', '2025-06-15 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 250, 'canceled', '2025-06-15 10:05:00', '2025-06-15 10:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 251, 'paid', '2025-07-17 11:00:00', '2025-07-17 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 252, 'paid', '2025-07-17 11:05:00', '2025-07-17 11:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 253, 'reserved', '2025-07-18 12:00:00', '2025-07-25 12:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 254, 'canceled', '2025-06-16 13:00:00', '2025-06-16 13:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 255, 'paid', '2025-07-19 14:00:00', '2025-07-19 14:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 256, 'paid', '2025-07-19 14:05:00', '2025-07-19 14:20:00');


    INSERT INTO Reservation (user_id, ticket_id, status, reservation_time, expiration_time) VALUES
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 257, 'paid', '2025-07-20 08:00:00', '2025-07-20 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 258, 'reserved', '2025-07-21 09:00:00', '2025-07-28 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 259, 'canceled', '2025-06-20 10:00:00', '2025-06-20 10:15:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 260, 'paid', '2025-07-22 08:00:00', '2025-07-22 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 261, 'paid', '2025-07-22 08:05:00', '2025-07-22 08:20:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 262, 'reserved', '2025-07-23 09:00:00', '2025-07-30 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 263, 'canceled', '2025-06-21 10:00:00', '2025-06-21 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 264, 'paid', '2025-07-24 11:00:00', '2025-07-24 11:15:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 265, 'paid', '2025-07-25 08:00:00', '2025-07-25 08:15:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 266, 'paid', '2025-07-26 08:00:00', '2025-07-26 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 267, 'paid', '2025-07-26 08:05:00', '2025-07-26 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 268, 'reserved', '2025-07-27 09:00:00', '2025-08-03 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 269, 'reserved', '2025-07-27 09:05:00', '2025-08-03 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 270, 'canceled', '2025-06-22 10:00:00', '2025-06-22 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 271, 'paid', '2025-07-28 11:00:00', '2025-07-28 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 272, 'reserved', '2025-07-29 12:00:00', '2025-08-05 12:00:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 273, 'paid', '2025-07-01 08:00:00', '2025-07-01 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 274, 'paid', '2025-07-01 08:05:00', '2025-07-01 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 275, 'paid', '2025-07-01 08:10:00', '2025-07-01 08:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 276, 'paid', '2025-07-01 08:15:00', '2025-07-01 08:30:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 277, 'reserved', '2025-07-02 09:00:00', '2025-07-09 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 278, 'reserved', '2025-07-02 09:05:00', '2025-07-09 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 279, 'reserved', '2025-07-02 09:10:00', '2025-07-09 09:10:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 280, 'reserved', '2025-07-02 09:15:00', '2025-07-09 09:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 281, 'canceled', '2025-06-03 10:00:00', '2025-06-03 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 282, 'canceled', '2025-06-03 10:05:00', '2025-06-03 10:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 283, 'canceled', '2025-06-03 10:10:00', '2025-06-03 10:25:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 284, 'paid', '2025-07-03 11:00:00', '2025-07-03 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 285, 'paid', '2025-07-03 11:05:00', '2025-07-03 11:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 286, 'reserved', '2025-07-04 12:00:00', '2025-07-11 12:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 287, 'canceled', '2025-06-04 13:00:00', '2025-06-04 13:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 288, 'paid', '2025-07-05 14:00:00', '2025-07-05 14:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 289, 'paid', '2025-07-05 14:05:00', '2025-07-05 14:20:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 290, 'paid', '2025-07-06 08:00:00', '2025-07-06 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 291, 'reserved', '2025-07-07 09:00:00', '2025-07-14 09:00:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 292, 'paid', '2025-07-08 08:00:00', '2025-07-08 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 293, 'reserved', '2025-07-09 09:00:00', '2025-07-16 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 294, 'canceled', '2025-06-05 10:00:00', '2025-06-05 10:15:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 295, 'paid', '2025-07-10 08:00:00', '2025-07-10 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 296, 'paid', '2025-07-10 08:05:00', '2025-07-10 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 297, 'reserved', '2025-07-11 09:00:00', '2025-07-18 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 298, 'reserved', '2025-07-11 09:05:00', '2025-07-18 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 299, 'canceled', '2025-06-06 10:00:00', '2025-06-06 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 300, 'paid', '2025-07-12 11:00:00', '2025-07-12 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 301, 'reserved', '2025-07-13 12:00:00', '2025-07-20 12:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 302, 'paid', '2025-07-14 14:00:00', '2025-07-14 14:15:00'),

    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 303, 'paid', '2025-07-15 08:00:00', '2025-07-15 08:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 304, 'paid', '2025-07-15 08:05:00', '2025-07-15 08:20:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 305, 'reserved', '2025-07-16 09:00:00', '2025-07-23 09:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 306, 'reserved', '2025-07-16 09:05:00', '2025-07-23 09:05:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 307, 'canceled', '2025-06-07 10:00:00', '2025-06-07 10:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 308, 'paid', '2025-07-17 11:00:00', '2025-07-17 11:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 309, 'reserved', '2025-07-18 12:00:00', '2025-07-25 12:00:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 310, 'canceled', '2025-06-08 13:00:00', '2025-06-08 13:15:00'),
    ((SELECT user_id FROM User WHERE user_type = 'CUSTOMER' ORDER BY RAND() LIMIT 1), 311, 'paid', '2025-07-19 14:00:00', '2025-07-19 14:15:00');

    UPDATE Reservation
    SET Reservation.status = 'paid'
    WHERE Reservation.reservation_id > 50;

    UPDATE Reservation 
    SET Reservation.status = 'paid'
    WHERE Reservation.status = 'reserved' AND Reservation.reservation_id < 47;


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

    INSERT INTO Payment (user_id, reservation_id, amount, payment_method, payment_status, payment_date)
    SELECT
        r.user_id,
        r.reservation_id,
        tr.price,
        CASE MOD(r.reservation_id, 3)
            WHEN 0 THEN 'credit_card'
            WHEN 1 THEN 'wallet'
            ELSE 'crypto'
        END,
        'completed',
        DATE_ADD(r.reservation_time, INTERVAL FLOOR(5 + RAND() * 10) MINUTE)
    FROM
        Reservation r
    JOIN
        Ticket ti ON r.ticket_id = ti.ticket_id
    JOIN
        Travel tr ON ti.travel_id = tr.travel_id
    WHERE
        r.status = 'paid'
        AND NOT EXISTS (SELECT 1 FROM Payment p WHERE p.reservation_id = r.reservation_id);

    UPDATE Travel t
    LEFT JOIN (
        SELECT
            ti.travel_id,
            COUNT(ti.ticket_id) AS active_reservations_count
        FROM
            Ticket ti
        JOIN
            Reservation r ON ti.ticket_id = r.ticket_id
        WHERE
            r.status IN ('paid', 'reserved')
        GROUP BY
            ti.travel_id
    ) AS active_counts ON t.travel_id = active_counts.travel_id
    SET
        t.remaining_capacity = t.total_capacity - IFNULL(active_counts.active_reservations_count, 0);

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
        
    INSERT INTO ReservationChange (reservation_id, support_id, prev_status, next_status) VALUES
    (1, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'paid', 'canceled'),
    (2, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'paid', 'canceled'),
    (3, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'reserved', 'canceled'),
    (5, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'paid', 'canceled'),
    (6, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'reserved', 'canceled'),
    (7, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'paid', 'canceled'),
    (8, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'paid', 'canceled'),
    (10, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'reserved', 'canceled'),
    (11, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'paid', 'canceled'),
    (12, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'paid', 'canceled'),
    (13, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'reserved', 'canceled'),
    (15, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'paid', 'canceled'),
    (16, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'reserved', 'canceled'),
    (17, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'paid', 'canceled'),
    (18, (SELECT user_id FROM User WHERE user_type = 'ADMIN' ORDER BY RAND() LIMIT 1), 'paid', 'canceled');

    UPDATE Reservation SET status = 'canceled' WHERE reservation_id IN (1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18);

    UPDATE Travel t
    LEFT JOIN (
        SELECT
            ti.travel_id,
            COUNT(ti.ticket_id) AS active_reservations_count
        FROM
            Ticket ti
        JOIN
            Reservation r ON ti.ticket_id = r.ticket_id
        WHERE
            r.status IN ('paid', 'reserved')
        GROUP BY
            ti.travel_id
    ) AS active_counts ON t.travel_id = active_counts.travel_id
    SET
        t.remaining_capacity = t.total_capacity - IFNULL(active_counts.active_reservations_count, 0);