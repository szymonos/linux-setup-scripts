/**
 * Lightbox / zoom enhancement for diagrams.
 * Adds click-to-zoom, pan & wheel-zoom behaviour to mermaid diagrams.
 */
(function() {
    const createLightbox = (svg) => {
        if (document.querySelector('.mermaid-lightbox-overlay')) {
            return;
        }

        const overlay = document.createElement('div');
        overlay.className = 'mermaid-lightbox-overlay';

        const clonedSvg = svg.cloneNode(true);
        clonedSvg.className = 'mermaid-lightbox-svg';
        clonedSvg.style.maxWidth = '90%';
        clonedSvg.style.maxHeight = '90%';
        clonedSvg.style.cursor = 'grab';

        const closeBtn = document.createElement('button');
        closeBtn.className = 'mermaid-lightbox-close';
        closeBtn.innerHTML = '&times;';

        overlay.appendChild(clonedSvg);
        overlay.appendChild(closeBtn);
        document.body.appendChild(overlay);

        addInteraction(overlay, clonedSvg);

        const closeLightbox = () => {
            if (document.body.contains(overlay)) {
                document.body.removeChild(overlay);
            }
            document.removeEventListener('keydown', onKeydown);
        };

        const onKeydown = (e) => {
            if (e.key === 'Escape') closeLightbox();
        };

        overlay.addEventListener('click', closeLightbox);
        closeBtn.addEventListener('click', closeLightbox);
        clonedSvg.addEventListener('click', e => e.stopPropagation());
        document.addEventListener('keydown', onKeydown);
    };

    const addInteraction = (container, svg) => {
        let scale = 1, pointX = 0, pointY = 0;
        let isDragging = false, startPos = { x: 0, y: 0 };

        svg.style.transformOrigin = 'center';
        svg.style.transition = 'transform 0.1s ease-out';

        const setTransform = () => {
            svg.style.transform = `translate(${pointX}px, ${pointY}px) scale(${scale})`;
        };

        svg.addEventListener('mousedown', e => {
            e.stopPropagation();
            isDragging = true;
            startPos = { x: e.clientX - pointX, y: e.clientY - pointY };
            svg.style.cursor = 'grabbing';
        });

        window.addEventListener('mousemove', e => {
            if (!isDragging) return;
            pointX = e.clientX - startPos.x;
            pointY = e.clientY - startPos.y;
            setTransform();
        });

        window.addEventListener('mouseup', () => {
            isDragging = false;
            svg.style.cursor = 'grab';
        });

        container.addEventListener('wheel', e => {
            e.preventDefault();
            const delta = e.deltaY < 0 ? 0.1 : -0.1;
            scale = Math.max(0.2, Math.min(10, scale + delta));
            setTransform();
        }, { passive: false });
    };

    const enhanceDiagram = (diagramDiv) => {
        if (diagramDiv.dataset.enhanced) return;
        diagramDiv.dataset.enhanced = 'true';
        diagramDiv.style.cursor = 'zoom-in';

        diagramDiv.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopImmediatePropagation();

            const svg = diagramDiv.querySelector('svg');
            if (svg) {
                createLightbox(svg);
            }
        }, true);
    };

    const scanAndEnhance = () => {
        const containers = document.querySelectorAll('.mermaid');
        containers.forEach(container => {
            const svg = container.querySelector('svg');
            if (svg) {
                enhanceDiagram(container);
            }
        });
    };

    const waitForRenderedSVGs = () => {
        const maxAttempts = 40;
        let attempts = 0;

        const check = () => {
            attempts++;
            const svgs = document.querySelectorAll('.mermaid svg');
            if (svgs.length > 0) {
                scanAndEnhance();
            }

            if (attempts < maxAttempts) {
                setTimeout(check, 150);
            }
        };

        check();
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', waitForRenderedSVGs);
    } else {
        waitForRenderedSVGs();
    }
})();
