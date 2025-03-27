CREATE TABLE IF NOT EXISTS `d_garages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `location` varchar(100) NOT NULL,
  `spawn_location` varchar(100) NOT NULL,
  `vehicles` text NOT NULL,
  `type` enum('car','helicopter','boat') NOT NULL,
  `blip` tinyint(1) NOT NULL DEFAULT 1,
  `job` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

ALTER TABLE jobs
ADD COLUMN `stash_location` TEXT DEFAULT NULL,
ADD COLUMN `stash_capacity` INT(11) DEFAULT 0,
ADD COLUMN `stash_slots` INT(11) DEFAULT 0;
