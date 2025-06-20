/*
  # Add sample descriptions for existing pieces

  1. Updates
    - Add sample piece_description content for all existing pieces
    - Uses markdown formatting to demonstrate the feature
    - Includes various types of content (social causes, artistic mediums, etc.)

  2. Content
    - Each description includes markdown formatting examples
    - Descriptions are relevant to peace and social causes
    - Varied length and style to show flexibility
*/

-- Update pieces with sample descriptions using markdown formatting
UPDATE pieces SET piece_description = 
CASE 
  WHEN title ILIKE '%peace%' OR title ILIKE '%harmony%' THEN
    '**A Vision of Unity**

This piece explores the *universal language of peace* that transcends cultural boundaries. Through collaborative artistic expression, we aim to create a bridge between communities and foster understanding.

**Key Themes:**
- Cross-cultural dialogue
- Community healing
- Artistic collaboration

[Learn more about our peace initiatives](https://example.com/peace-initiatives)

*"Art has the power to heal wounds that words cannot reach."*'

  WHEN title ILIKE '%hope%' OR title ILIKE '%future%' THEN
    '**Building Tomorrow Together**

This collaborative work represents our collective *hope for a better future*. Each contributor brings their unique perspective to create something greater than the sum of its parts.

**What makes this special:**
- **Community-driven**: Created by local artists and activists
- **Sustainable impact**: Proceeds support ongoing community programs  
- **Educational outreach**: Includes workshops for youth

The piece serves as both artistic expression and *call to action* for positive change in our communities.'

  WHEN title ILIKE '%justice%' OR title ILIKE '%equality%' THEN
    '**Voices for Justice**

A powerful multimedia experience that amplifies *marginalized voices* and calls for systemic change. This piece combines visual art, spoken word, and music to create an immersive journey through the struggle for equality.

**Featured Elements:**
- Original poetry by community members
- Visual representations of historical and contemporary struggles
- Interactive audio experiences

*This work is dedicated to all those who continue to fight for justice and equality.*

[Support our justice initiatives](https://example.com/justice-fund)'

  WHEN title ILIKE '%environment%' OR title ILIKE '%earth%' OR title ILIKE '%nature%' THEN
    '**Healing Our Planet**

An *environmental call to action* through artistic expression. This piece visualizes the beauty of our natural world while highlighting the urgent need for environmental protection and restoration.

**Environmental Focus:**
- **Climate awareness**: Showcasing the effects of climate change
- **Conservation efforts**: Highlighting successful restoration projects
- **Community action**: Inspiring local environmental initiatives

The artwork incorporates *sustainable materials* and eco-friendly production methods, embodying the environmental message it seeks to convey.

*"We do not inherit the earth from our ancestors; we borrow it from our children."*'

  WHEN title ILIKE '%community%' OR title ILIKE '%together%' THEN
    '**Strength in Unity**

This collaborative piece celebrates the *power of community* and the beautiful diversity that makes us stronger together. Created through workshops and community gatherings, it represents the collective voice of our neighborhood.

**Community Impact:**
- Brought together **50+ local artists**
- Hosted *12 community workshops*
- Raised funds for local youth programs

The creation process was as important as the final piece, fostering new friendships and strengthening community bonds.

[Join our community events](https://example.com/community-events)'

  WHEN title ILIKE '%love%' OR title ILIKE '%heart%' THEN
    '**Love as Resistance**

In a world often divided by fear and hatred, this piece stands as a testament to *love as the ultimate form of resistance*. Through gentle yet powerful imagery and sound, we explore how love can transform communities and heal wounds.

**Artistic Elements:**
- **Visual poetry**: Text and image interweaving
- **Ambient soundscape**: Creating emotional resonance
- **Interactive components**: Inviting viewer participation

*Love is not just an emotion—it''s an action, a choice, and a revolutionary force for change.*'

  WHEN title ILIKE '%music%' OR title ILIKE '%song%' OR title ILIKE '%sound%' THEN
    '**Harmonies for Change**

Music has always been a *catalyst for social movement*. This piece combines original compositions with field recordings from protests, celebrations, and community gatherings to create a sonic tapestry of resistance and hope.

**Musical Journey:**
- **Original compositions** by local musicians
- *Field recordings* from community events
- **Collaborative arrangements** featuring diverse instruments

The piece invites listeners to experience the *emotional power of collective voice* and the way music can unite people across differences.

[Listen to our community playlist](https://example.com/community-music)'

  WHEN title ILIKE '%art%' OR title ILIKE '%create%' OR title ILIKE '%express%' THEN
    '**The Power of Creative Expression**

This meta-artistic piece explores *art as a tool for social change*. Through layered visual elements and interactive components, we examine how creative expression can challenge systems, inspire action, and build community.

**Creative Process:**
- **Open studio sessions** with community participation
- *Collaborative decision-making* throughout creation
- **Documentation** of the artistic journey

The work serves as both artwork and *manifesto* for the transformative power of community-based creative practice.

*"Art is not what you see, but what you make others see." - Edgar Degas*'

  ELSE
    '**A Journey of Discovery**

This unique piece invites viewers to embark on a *journey of personal and collective discovery*. Through thoughtful composition and meaningful symbolism, we explore themes of growth, connection, and positive transformation.

**Key Features:**
- **Symbolic imagery** representing growth and change
- *Interactive elements* encouraging viewer engagement
- **Community stories** woven throughout the piece

Each viewing reveals new layers of meaning, making this a work that *grows with its audience* and continues to inspire long after the first encounter.

The piece stands as a testament to the power of *collaborative creativity* and the beautiful things that emerge when communities come together with shared purpose.'
END
WHERE piece_description IS NULL OR piece_description = '';