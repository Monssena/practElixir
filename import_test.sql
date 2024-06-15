-- Creation of a test base...

CREATE DATABASE test;

USE test;

CREATE TABLE Individuals
(
    id               INT AUTO_INCREMENT PRIMARY KEY,
    first_name       VARCHAR(30) NOT NULL,
    last_name        VARCHAR(30) NOT NULL,
    middle_name      VARCHAR(30),
    passport         VARCHAR(10) NOT NULL,
    taxpayer_number  VARCHAR(12) NOT NULL,
    insurance_number VARCHAR(11) NOT NULL,
    driver_licence   VARCHAR(10),
    extra_documents  VARCHAR(255),
    notes            VARCHAR(255)
) ENGINE = InnoDB
  DEFAULT CHARSET = cp1251;

INSERT INTO Individuals (first_name, last_name, middle_name, passport, taxpayer_number, insurance_number,
                         driver_licence, extra_documents, notes)
VALUES ('Ivan', 'Ivanov', 'Ivanovich', '1234567890', '123456789012', '12345678901', '1234567890',
        'Document 1, Document 2', 'Some notes'),
       ('Petr', 'Petrov', 'Petrovich', '0987654321', '210987654321', '10987654321', '0987654321', 'Document 3',
        'Other notes'),
       ('Svetlana', 'Svetlova', 'Svetlanovna', '1122334455', '987654321098', '22334455667', '4455667788',
        'Document 4, Document 5', 'Notes for Svetlana'),
       ('Alexey', 'Alekseev', 'Alexeevich', '5566778899', '876543210987', '33445566778', '1122334455', 'Document 6',
        'Notes for Alexey'),
       ('Maria', 'Marina', 'Marinovna', '6677889900', '765432109876', '44556677889', '2233445566', 'Document 7',
        'Notes for Maria');
