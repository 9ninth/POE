# Project: Panther Only Eats (POE)

## Overview
Panther Only Eats is a web application designed to track and display free food events on campus. The goal is to aggregate data from the university's event portal and present it in a user-friendly format.

## Data Pipeline
1. **Source**: Scrape events from [Pin GSU](https://pin.gsu.edu/events?categories=8776&perks=FreeFood).
2. **Extraction**: The scraping logic is currently handled by `scraper.js`.
3. **Processing**: 
   - Data is initially saved to a CSV file.
   - Example successful scrape: `C:\Users\juani\poe\POE\events_export_2026-02-26.csv`.
   - **Requirement**: Implement logic to check for and remove duplicate entries.
4. **Storage**: Populate the cleaned data into a Google Cloud database.

## Web Application Design
The application is currently in a starter state and requires a fundamental redesign. It will display event data fetched from the database.

### Display Approaches
We are designing the UI with two distinct views:
1. **Grid View**
2. **Tab Display**

### Event Details
Each event card or entry should display the following information:
- **Event Title**
- **Organization**
- **Location**
- **Time**
- **Date**
- **RSVP Link**: Constructed using the event ID template: `https://pin.gsu.edu/event/{id}`