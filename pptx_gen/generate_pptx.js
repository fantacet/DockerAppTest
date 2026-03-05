const pptxgen = require('pptxgenjs');
const html2pptx = require('C:/DockerAppTest/.agents/skills/pptx-official/scripts/html2pptx.js');
const path = require('path');

async function createPresentation() {
    const pptx = new pptxgen();
    pptx.layout = 'LAYOUT_16x9';
    pptx.author = 'Antigravity';
    pptx.title = 'Office AI / ISA Edge 架構解析';

    const slides = [
        'slide1.html',
        'slide2.html',
        'slide3.html',
        'slide4.html',
        'slide5.html'
    ];

    for (const slideFile of slides) {
        console.log(`Processing ${slideFile}...`);
        await html2pptx(path.join(__dirname, slideFile), pptx);
    }

    const outFile = path.join(__dirname, 'architecture_presentation.pptx');
    await pptx.writeFile({ fileName: outFile });
    console.log(`Presentation created successfully at ${outFile}!`);
}

createPresentation().catch(console.error);
