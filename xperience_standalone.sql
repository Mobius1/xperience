CREATE TABLE IF NOT EXISTS `user_experience` (
    `identifier` varchar(40) NOT NULL,
    `xp` int(11) DEFAULT 0,
    `rank` int(11) DEFAULT 1,
    UNIQUE KEY `unique_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;