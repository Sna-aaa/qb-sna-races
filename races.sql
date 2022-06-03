CREATE TABLE IF NOT EXISTS `races` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `track` varchar(50) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `type` varchar(10) NOT NULL,
  `car` varchar(50) NOT NULL,
  `best` int(11) DEFAULT NULL,
  `lapdetail` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4;
