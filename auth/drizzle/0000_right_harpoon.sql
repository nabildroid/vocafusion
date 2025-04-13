CREATE TABLE `users` (
	`uid` text PRIMARY KEY NOT NULL,
	`displayName` text DEFAULT 'User' NOT NULL,
	`createdAt` integer DEFAULT (CURRENT_TIMESTAMP),
	`email` text NOT NULL,
	`claims` text
);
--> statement-breakpoint
CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`);