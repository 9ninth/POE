// Run this script in the Chrome Developer Console (F12 -> Console) on the events page

function downloadCSV(data, filename) {
    if (!data.length) {
        console.warn("No data to download.");
        return;
    }

    const headers = Object.keys(data[0]);
    const csvRows = [];
    
    // Add header row
    csvRows.push(headers.map(header => `"${header}"`).join(','));

    // Add data rows
    for (const row of data) {
        const values = headers.map(header => {
            const val = row[header] !== undefined ? '' + row[header] : '';
            // Escape double quotes by doubling them
            const escaped = val.replace(/"/g, '""');
            return `"${escaped}"`;
        });
        csvRows.push(values.join(','));
    }

    const csvString = csvRows.join('\n');
    const blob = new Blob([csvString], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.setAttribute('hidden', '');
    a.setAttribute('href', url);
    a.setAttribute('download', filename);
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
}

function scrapeEvents() {
    // 1. Find all event cards. Based on the snippet, the outer container seems generic, 
    // but the card itself has "MuiPaper-root MuiCard-root". 
    // We'll look for the anchor tag wrapping the card which gives us the event link/ID.
    const eventCards = Array.from(document.querySelectorAll('a[href^="/event/"]'));
    
    const events = eventCards.map(cardLink => {
        try {
            // -- ID --
            const href = cardLink.getAttribute('href');
            const id = 'evt-' + href.split('/').pop().split('?')[0];

            // -- Title --
            const titleEl = cardLink.querySelector('h3');
            const title = titleEl ? titleEl.textContent.trim() : 'Untitled Event';

            // -- Image --
            const imgDiv = cardLink.querySelector('div[role="img"]');
            let imageUrl = '';
            if (imgDiv) {
                const style = imgDiv.getAttribute('style');
                const match = style.match(/src="([^"]+)"/) || style.match(/url\("?([^"]+)"?\)/);
                if (match) imageUrl = match[1];
            }

            // -- Date & Time --
            // The snippet showed date/time in an aria-label or visible text inside an div with specific style
            // aria-label="happening on Wednesday, February 25 at 8:30AM EST"
            const dateEl = cardLink.querySelector('div[aria-label^="happening on"]');
            
            let date = '';
            let time = '';
            
            if (dateEl) {
                const ariaLabel = dateEl.getAttribute('aria-label');
                // Remove prefix "happening on "
                const dateTimeStr = ariaLabel.replace('happening on ', '');
                
                // Typical format: "Wednesday, February 25 at 8:30AM EST"
                // Split by " at " to separate date part from time part
                const parts = dateTimeStr.split(' at ');
                if (parts.length >= 2) {
                    const datePart = parts[0]; // "Wednesday, February 25"
                    time = parts[1]; // "8:30AM EST"
                    
                    // Parse date to 'YYYY-MM-DD' if possible. 
                    // Note: The snippet lacks a year, so we might need to guess the year (current or next).
                    // For now, let's keep the raw string or try to parse with current year.
                    const currentYear = new Date().getFullYear();
                    const parsedDate = new Date(`${datePart}, ${currentYear}`);
                    
                    // If the date is in the past (e.g. earlier this year where it should be next year), adjust year
                    // (This logic can be refined)
                    if (!isNaN(parsedDate)) {
                        date = parsedDate.toISOString().split('T')[0];
                    } else {
                        date = datePart; // Fallback
                    }
                } else {
                    date = dateTimeStr;
                }
            }

            // -- Location --
            // aria-label="located at Student Wellness, Suite 484 Student Center West"
            const locEl = cardLink.querySelector('div[aria-label^="located at"]');
            let location = 'TBD';
            if (locEl) {
                location = locEl.getAttribute('aria-label').replace('located at ', '');
            }

            // -- Description / Host --
            // aria-label="hosted by Be Well Panthers Health & Wellness"
            const hostEl = cardLink.querySelector('span[aria-label^="hosted by"]');
            let description = '';
            if (hostEl) {
                description = hostEl.getAttribute('aria-label');
            }

            // -- Type --
            // We don't have a clear "type" in the snippet (Cafe/Restaurant), so we'll randomize or default
            // based on keywords in title?
            let type = 'cafe'; // default
            const t = title.toLowerCase();
            if (t.includes('dinner') || t.includes('steak') || t.includes('sushi') || t.includes('restaurant')) {
                type = 'restaurant';
            }

            // -- Mock RSVP Count (Random 10-100) --
            const rsvpCount = Math.floor(Math.random() * 90) + 10;

            // -- Mock Color (Random) --
            const colors = ['blue', 'dark', 'pale', 'white'];
            const color = colors[Math.floor(Math.random() * colors.length)];

            return {
                id,
                title,
                type,
                location,
                date, // YYYY-MM-DD
                time, // e.g. "8:30 AM EST"
                color,
                description,
                rsvpCount,
                imageUrl
            };

        } catch (err) {
            console.error('Error parsing card', err);
            return null;
        }
    }).filter(e => e !== null);

    console.log(`Parsed ${events.length} events`);
    downloadCSV(events, `events_export_${new Date().toISOString().slice(0,10)}.csv`);
    return events;
}

// Run it
scrapeEvents();
