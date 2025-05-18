import { chromium } from 'playwright';
import express from 'express';

const app = express();
const port = process.env.PORT || 8000;

app.use(express.json());

async function getImageSrc(pageUrl) {
  // Launch browser
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  try {
    // Navigate to the page
    await page.goto(pageUrl, { waitUntil: 'networkidle' }); // Added waitUntil for better reliability

    const imgSrc = await page.locator('img.x168nmei.x13lgxp2.x5pf9jr.xo71vjh.x5yr21d.xl1xv1r.xh8yej3[referrerpolicy="origin-when-cross-origin"][alt=""]').getAttribute('src');
    
    // Return the src
    return imgSrc;
  } catch (error) {
    console.error('Error in getImageSrc:', error);
    throw error; // Or return { error: error.message }
  } finally {
    // Close browser
    await browser.close();
  }
}

// API Endpoint
app.get('/api/image-src', async (req, res) => {
  const { pageUrl } = req.query;

  if (!pageUrl) {
    return res.status(400).json({ error: 'pageUrl query parameter is required' });
  }

  try {
    const src = await getImageSrc(pageUrl);
    if (src) {
      res.json({ imageUrl: src });
    } else {
      // This case might not be reached if getImageSrc throws an error as suggested
      res.status(404).json({ error: 'Image source not found or an error occurred during scraping.' });
    }
  } catch (error) {
    // Log the detailed error on the server
    console.error(`Error processing ${pageUrl}:`, error);
    // Send a generic error message to the client
    res.status(500).json({ error: 'Failed to retrieve image source due to an internal server error.' });
  }
});

app.listen(port, () => {
  console.log(`Image scrapper API listening at http://localhost:${port}`);
});
