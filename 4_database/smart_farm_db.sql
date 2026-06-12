-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jun 12, 2026 at 08:44 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `smart_farm_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `sensor_logs`
--

CREATE TABLE `sensor_logs` (
  `log_id` int(11) NOT NULL,
  `serial_number` varchar(50) NOT NULL,
  `temp` float DEFAULT NULL,
  `humi` float DEFAULT NULL,
  `soil_moisture` float DEFAULT NULL,
  `light_status` tinyint(1) DEFAULT 0,
  `pump_status` tinyint(1) DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sensor_logs`
--

INSERT INTO `sensor_logs` (`log_id`, `serial_number`, `temp`, `humi`, `soil_moisture`, `light_status`, `pump_status`, `created_at`) VALUES
(1, 'SN-S8DRTED', 31.8, 62.5, 48.2, 0, 0, '2026-05-06 09:00:00'),
(2, 'SN-S8DRTED', 33.2, 59.1, 44, 0, 0, '2026-05-06 10:00:00'),
(3, 'SN-S8DRTED', 34.9, 54.3, 39.1, 0, 1, '2026-05-06 11:00:00'),
(4, 'SN-S8DRTED', 33.5, 57.8, 52.4, 0, 1, '2026-05-06 12:00:00'),
(5, 'SN-S8DRTED', 31.2, 65, 71.3, 0, 0, '2026-05-06 13:00:00'),
(6, 'SN-S8DRTED', 30.5, 68.2, 69, 0, 0, '2026-05-06 14:00:00'),
(7, 'SN-S8DRTED', 29.9, 71.5, 65.8, 0, 0, '2026-05-06 15:00:00'),
(8, 'SN-S8DRTED', 31.1, 67.4, 61.2, 0, 0, '2026-05-06 16:00:00'),
(9, 'SN-S8DRTED', 32.7, 61, 55.5, 0, 0, '2026-05-06 17:00:00'),
(10, 'SN-S8DRTED', 34.2, 56.5, 37.8, 0, 1, '2026-05-06 18:00:00'),
(11, 'SN-S8DRTED', 25, 60, 50, 0, 0, '2026-05-25 20:55:18'),
(12, 'SN-S8DRTED', 25, 60, 50, 0, 0, '2026-05-25 20:56:18'),
(13, 'SN-S8DRTED', 28.6, 50.1, 9, 0, 0, '2026-05-26 04:20:54'),
(14, 'SN-S8DRTED', 28.6, 49.9, 9, 0, 0, '2026-05-26 04:21:54'),
(15, 'SN-S8DRTED', 28.6, 49.4, 9, 0, 0, '2026-05-26 04:22:54'),
(16, 'SN-S8DRTED', 26.7, 54.9, 10, 0, 0, '2026-05-26 04:52:52'),
(17, 'SN-S8DRTED', 26.6, 54.8, 9, 1, 1, '2026-05-26 04:53:52'),
(18, 'SN-S8DRTED', 30.7, 50.5, 9, 0, 0, '2026-05-27 07:31:33'),
(19, 'SN-VTKHMWD', 29.6, 53, 7, 0, 0, '2026-05-27 07:31:33'),
(20, 'SN-S8DRTED', 30, 50.4, 9, 0, 0, '2026-05-27 07:32:33'),
(21, 'SN-VTKHMWD', 29.6, 52.2, 8, 0, 0, '2026-05-27 07:32:33'),
(22, 'SN-S8DRTED', 29.6, 50.4, 8, 0, 0, '2026-05-27 07:33:33'),
(23, 'SN-VTKHMWD', 29.6, 51.4, 8, 0, 0, '2026-05-27 07:33:36'),
(24, 'SN-S8DRTED', 29.4, 50.5, 9, 0, 0, '2026-05-27 07:34:36'),
(25, 'SN-VTKHMWD', 29.6, 51, 8, 0, 0, '2026-05-27 07:34:36'),
(26, 'SN-S8DRTED', 29.3, 50.8, 8, 0, 0, '2026-05-27 07:35:36'),
(27, 'SN-VTKHMWD', 29.6, 50.6, 8, 0, 0, '2026-05-27 07:35:39'),
(28, 'SN-S8DRTED', 29.2, 50.5, 9, 0, 0, '2026-05-27 07:36:39'),
(29, 'SN-VTKHMWD', 29.6, 50.8, 8, 0, 0, '2026-05-27 07:36:39'),
(30, 'SN-S8DRTED', 30, 50.1, 9, 0, 0, '2026-05-27 07:37:39'),
(31, 'SN-VTKHMWD', 29.5, 50.4, 8, 0, 0, '2026-05-27 07:37:39'),
(32, 'SN-VTKHMWD', 29.4, 50.1, 8, 0, 0, '2026-05-27 07:38:39'),
(33, 'SN-FSH64G4', NULL, NULL, 100, 0, 0, '2026-05-29 02:08:48'),
(34, 'SN-FSH64G4', NULL, NULL, 93, 0, 0, '2026-05-29 02:09:48'),
(35, 'SN-FSH64G4', NULL, NULL, 100, 0, 0, '2026-05-29 02:10:48'),
(36, 'SN-FSH64G4', NULL, NULL, 100, 0, 0, '2026-05-29 02:11:51'),
(37, 'SN-FSH64G4', NULL, NULL, 100, 0, 0, '2026-05-29 02:12:51'),
(38, 'SN-FSH64G4', NULL, NULL, 100, 0, 0, '2026-05-29 02:13:51'),
(39, 'SN-FSH64G4', NULL, NULL, 100, 0, 0, '2026-05-29 02:31:00'),
(40, 'SN-FSH64G4', NULL, NULL, 100, 0, 0, '2026-05-29 02:33:32'),
(41, 'SN-FSH64G4', NULL, NULL, 100, 0, 0, '2026-05-29 02:34:32'),
(42, 'SN-S8DRTED', 28.1, 55.3, 9, 0, 0, '2026-06-04 09:27:36'),
(43, 'SN-S8DRTED', 27.9, 56.5, 10, 0, 0, '2026-06-04 09:28:36'),
(44, 'SN-FSH64G4', 27.7, 58.8, 8, 0, 0, '2026-06-04 09:31:35'),
(45, 'SN-S8DRTED', 27.4, 59.3, 9, 0, 0, '2026-06-04 09:31:37'),
(46, 'SN-FSH64G4', 27.6, 59.3, 8, 0, 1, '2026-06-04 09:32:35'),
(47, 'SN-S8DRTED', 27.3, 59.5, 9, 0, 0, '2026-06-04 09:32:40'),
(48, 'SN-FSH64G4', 27.4, 58.8, 8, 0, 0, '2026-06-04 09:33:35'),
(49, 'SN-S8DRTED', 27.1, 58.8, 10, 0, 0, '2026-06-04 09:33:43'),
(50, 'SN-FSH64G4', 27.3, 57.7, 8, 0, 0, '2026-06-04 09:34:38'),
(51, 'SN-S8DRTED', 26.9, 57.3, 9, 0, 0, '2026-06-04 09:34:46'),
(52, 'SN-FSH64G4', 27.2, 56.8, 8, 0, 0, '2026-06-04 09:35:38'),
(53, 'SN-S8DRTED', 26.8, 57.8, 9, 1, 0, '2026-06-04 09:35:46'),
(54, 'SN-FSH64G4', 27.1, 58.2, 8, 0, 0, '2026-06-04 09:36:41'),
(55, 'SN-S8DRTED', 26.8, 58.9, 9, 0, 0, '2026-06-04 09:36:46'),
(56, 'SN-FSH64G4', 27.1, 60.1, 8, 0, 0, '2026-06-04 09:37:41'),
(57, 'SN-S8DRTED', 26.9, 61, 9, 0, 0, '2026-06-04 09:37:49'),
(58, 'SN-FSH64G4', 27.1, 61.4, 8, 0, 0, '2026-06-04 09:38:41'),
(59, 'SN-S8DRTED', 26.9, 62.3, 9, 0, 0, '2026-06-04 09:38:49'),
(60, 'SN-FSH64G4', 27.2, 61.4, 8, 0, 0, '2026-06-04 09:39:41'),
(61, 'SN-S8DRTED', 27, 61.8, 9, 0, 0, '2026-06-04 09:39:49'),
(62, 'SN-S8DRTED', 26.8, 60.9, 9, 0, 0, '2026-06-04 09:44:14'),
(63, 'SN-S8DRTED', 27.2, 47.8, 10, 0, 0, '2026-06-04 11:36:47'),
(64, 'SN-FSH64G4', 27.9, 46.2, 8, 0, 0, '2026-06-04 11:36:47'),
(65, 'SN-S8DRTED', 27.1, 46.5, 10, 0, 0, '2026-06-04 11:37:47'),
(66, 'SN-FSH64G4', 27.9, 46.3, 9, 0, 0, '2026-06-04 11:37:47'),
(67, 'SN-S8DRTED', 27.1, 46.2, 10, 0, 0, '2026-06-04 11:38:47'),
(68, 'SN-FSH64G4', 27.7, 45.9, 9, 0, 0, '2026-06-04 11:38:48'),
(69, 'SN-S8DRTED', 27, 46.3, 10, 1, 0, '2026-06-04 11:39:47'),
(70, 'SN-FSH64G4', 27.6, 46.4, 9, 0, 0, '2026-06-04 11:39:48'),
(71, 'SN-S8DRTED', 26.9, 46.2, 9, 1, 0, '2026-06-04 11:40:47'),
(72, 'SN-FSH64G4', 27.6, 46.2, 9, 0, 0, '2026-06-04 11:40:48'),
(73, 'SN-S8DRTED', 26.9, 46, 10, 1, 0, '2026-06-04 11:41:47'),
(74, 'SN-FSH64G4', 27.5, 46.2, 9, 0, 0, '2026-06-04 11:41:48'),
(75, 'SN-S8DRTED', 28, 86.1, 10, 1, 0, '2026-06-04 11:42:47'),
(76, 'SN-FSH64G4', 27.4, 46.2, 9, 0, 0, '2026-06-04 11:42:48'),
(77, 'SN-S8DRTED', 28.2, 46.4, 9, 1, 0, '2026-06-04 11:43:47'),
(78, 'SN-FSH64G4', 28.5, 48.4, 9, 0, 0, '2026-06-04 11:43:48'),
(79, 'SN-S8DRTED', 27.7, 46.5, 9, 0, 0, '2026-06-04 11:44:47'),
(80, 'SN-FSH64G4', 28.1, 45.6, 9, 0, 0, '2026-06-04 11:44:48'),
(81, 'SN-S8DRTED', 27.5, 48.1, 9, 0, 1, '2026-06-04 11:45:47'),
(82, 'SN-FSH64G4', 27.7, 45.9, 9, 0, 0, '2026-06-04 11:45:48'),
(83, 'SN-S8DRTED', 27.4, 45.7, 9, 0, 1, '2026-06-04 11:46:47'),
(84, 'SN-FSH64G4', 27.6, 46.1, 9, 1, 0, '2026-06-04 11:46:48'),
(85, 'SN-S8DRTED', 27.2, 45.6, 9, 0, 1, '2026-06-04 11:47:47'),
(86, 'SN-FSH64G4', 27.4, 46.2, 9, 0, 0, '2026-06-04 11:47:48'),
(87, 'SN-FSH64G4', 27.3, 45.9, 9, 0, 0, '2026-06-04 11:48:48'),
(88, 'SN-S8DRTED', 27.1, 45.4, 9, 0, 1, '2026-06-04 11:48:50'),
(89, 'SN-FSH64G4', 27.2, 45.9, 9, 0, 0, '2026-06-04 11:49:48'),
(90, 'SN-S8DRTED', 26.9, 45.7, 9, 0, 1, '2026-06-04 11:49:50'),
(91, 'SN-S8DRTED', 26.8, 45.7, 9, 0, 0, '2026-06-04 11:50:50'),
(92, 'SN-FSH64G4', 27.1, 46.1, 9, 0, 0, '2026-06-04 11:50:51'),
(93, 'SN-S8DRTED', 26.8, 46.1, 9, 0, 0, '2026-06-04 11:51:50'),
(94, 'SN-FSH64G4', 27.1, 46.2, 9, 0, 0, '2026-06-04 11:51:51'),
(95, 'SN-S8DRTED', NULL, NULL, 9, 0, 0, '2026-06-04 11:52:50'),
(96, 'SN-FSH64G4', 27.1, 48.3, 8, 0, 0, '2026-06-04 11:52:54'),
(97, 'SN-S8DRTED', NULL, NULL, 9, 0, 0, '2026-06-04 11:53:50'),
(98, 'SN-FSH64G4', 27.5, 64.8, 9, 0, 0, '2026-06-04 11:53:54'),
(99, 'SN-S8DRTED', NULL, NULL, 10, 0, 0, '2026-06-04 11:54:50'),
(100, 'SN-FSH64G4', 0, 0, 9, 0, 0, '2026-06-04 11:54:54');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `token_id` varchar(5) DEFAULT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `role` enum('user','admin') DEFAULT 'user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `token_id`, `username`, `password`, `created_at`, `role`) VALUES
(1, '12345', 'user', '1234', '2026-03-04 15:51:27', 'user'),
(2, '11345', 'user1', '1234', '2026-04-03 11:46:22', 'user'),
(3, '', 'admin', '1234', '2026-05-04 08:49:46', 'admin'),
(14, NULL, 'admin1', '1234', '2026-06-08 02:06:28', 'admin'),
(15, NULL, 'admin2', '1234', '2026-06-08 02:06:39', 'admin'),
(16, NULL, 'ATC1', '0000', '2026-06-08 02:06:58', 'admin'),
(17, NULL, 'ATC2', '0000', '2026-06-08 02:07:06', 'admin'),
(18, NULL, 'ATC3', '0000', '2026-06-08 02:07:16', 'admin'),
(19, NULL, 'ATC4', '0000', '2026-06-08 02:07:25', 'admin'),
(20, NULL, 'ATC5', '0000', '2026-06-08 02:07:32', 'admin'),
(21, '71298', 'UTC1', '0000', '2026-06-08 02:07:40', 'user'),
(23, '55541', 'UTC2', '0000', '2026-06-08 02:07:57', 'user'),
(24, '93809', 'UTC3', '0000', '2026-06-08 02:08:05', 'user'),
(25, '11347', 'UTC4', '0000', '2026-06-08 02:08:11', 'user'),
(26, '10040', 'UTC5', '0000', '2026-06-08 02:08:17', 'user'),
(27, '40111', 'user2', '1234', '2026-06-08 02:08:22', 'user');

-- --------------------------------------------------------

--
-- Table structure for table `user_farms`
--

CREATE TABLE `user_farms` (
  `user_id` int(11) NOT NULL,
  `serial_number` varchar(50) NOT NULL,
  `farm_name` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_farms`
--

INSERT INTO `user_farms` (`user_id`, `serial_number`, `farm_name`, `created_at`) VALUES
(2, 'SN-167ADN', 'melon2', '2026-05-28 19:24:39'),
(2, 'SN-FSH64G4', 'melon1', '2026-04-15 15:58:36'),
(1, 'SN-S8DRTED', 'Green Oak', '2026-04-15 15:38:16'),
(1, 'SN-VTKHMWD', 'Red Oak', '2026-04-21 06:55:43');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `sensor_logs`
--
ALTER TABLE `sensor_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `serial_number` (`serial_number`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `token_id` (`token_id`);

--
-- Indexes for table `user_farms`
--
ALTER TABLE `user_farms`
  ADD PRIMARY KEY (`serial_number`),
  ADD KEY `user_id` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `sensor_logs`
--
ALTER TABLE `sensor_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=101;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `sensor_logs`
--
ALTER TABLE `sensor_logs`
  ADD CONSTRAINT `sensor_logs_ibfk_1` FOREIGN KEY (`serial_number`) REFERENCES `user_farms` (`serial_number`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `user_farms`
--
ALTER TABLE `user_farms`
  ADD CONSTRAINT `user_farms_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
