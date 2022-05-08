class Xperience {
    constructor(options) {
        const config = {
            xp: 0,
            tick: 100,
            onInit: () => {},
            onChange: () => {},
            onRankChange: () => {},
            onStart: () => {},
            onEnd: () => {}
        };

        this.config = Object.assign({}, config, options);

        this.init();
    }

    init() {
        this.currentRank = 1;
        this.currentXP = this.config.xp;
        this.maxRank = Object.keys(this.config.ranks).length;
        this.maxXP = this.config.ranks[this.maxRank];
        this.currentRank = this.getRankFromXP();
        this.nextRank = this.currentRank + 1;

        const rankDiff = this.config.ranks[this.nextRank] - this.config.ranks[this.currentRank]
        this.rankProgress = ((rankDiff - (this.config.ranks[this.nextRank] - this.currentXP)) / rankDiff) * 100

        this.previousRank = 0;
        if (this.currentRank > 1) {
            this.previousRank = this.currentRank - 1;
        }

        this.config.onInit.call(this, this.rankProgress);
    }

    setXP(xp) {
        xp = parseInt(xp, 10);
        if (xp > this.currentXP) {
            this._update(xp - this.currentXP, true);
        } else {
            this._update(this.currentXP - xp, false);
        }
    }

    addXP(xp) {
        xp = parseInt(xp, 10);

        if (this.currentXP >= this.maxXP) {
            xp = 0;
        }

        if (this.currentXP + xp > this.maxXP) {
            xp = this.maxXP - this.currentXP;
        }

        this._update(xp, true);
    }

    removeXP(xp) {
        xp = parseInt(xp, 10);
        if (this.currentXP - xp <= 0) {
            xp = this.currentXP;
        }

        this._update(xp, false);
    }
	
    getRankFromXP(xp) {
        if ( xp === undefined ) {
            xp = this.currentXP;
        }
		
        const len = Object.keys(this.config.ranks).length;
        for (let id in this.config.ranks) {
            if (this.config.ranks.hasOwnProperty(id)) {
                const rank = parseInt(id, 10);

                if (rank < len) {
                    if (this.config.ranks[rank + 1] > xp) {
                        return rank;
                    }
                } else {
                    return rank;
                }
            }
        }
    }	

    _update(xp, add) {
		
        if ( this.running ) {
            return false;
        }
		
        xp = parseInt(xp, 10);

        const targetXP = add ? this.currentXP + xp : this.currentXP - xp;
        const ranks = this.config.ranks;
		
        let rank = this.currentRank;
        let n = this.currentXP;

        this.config.onStart.call(this, add);

        const animate = () => {
            if ((add && n < targetXP) || (!add && n > targetXP)) {
				
                this.running = true;
				
                let rankDiff =
                    this.currentRank < this.maxRank
                        ? ranks[rank + 1] - ranks[rank]
                        : ranks[this.maxRank] - ranks[this.maxRank - 1];
                const inc = rankDiff / this.config.tick;

                // increment XP
                n += add ? inc : -inc;

                // limit XP
                n = (add && n > targetXP) || (!add && n < targetXP) ? targetXP : n;

                this.currentXP = n;

                // progress bar
                this.rankProgress = ((rankDiff - (ranks[rank + 1] - n)) / rankDiff) * 100;
				
                if ( this.rankProgress >= 100 ) {
                    this.rankProgress = 0;
                }

                // indicator bar
                this.maxProgress =
                    targetXP > ranks[rank + 1]
                        ? 100
                        : 100 * ((targetXP - ranks[rank]) / rankDiff);
				
                // change callback
                this.config.onChange.call(
                    this,
                    this.rankProgress,
                    this.currentXP,
                    this.maxProgress,
                    add
                );

                // rank changed
                if (
                    (add && n >= ranks[rank + 1] && rank < this.maxRank) ||
                    (!add && n < ranks[rank] && rank > 1)
                ) {
                    const previousRank = rank;
                    let max = false;
                    let rankUp = false;
					
                    // increment / decrement rank
                    if (add) {
                        rank++;
                        rankUp = true;
                    } else {
                        rank--;
                    }
					
                    max = rank === this.maxRank;
					
                    this.currentRank = rank;

                    // new ranks
                    if ( !max ) {
                        this.nextRank = rank + 1;
                        this.previousRank = previousRank;
                        this.rankProgress = 0;
                    } else {
                        this.rankProgress = 100;
                        this.nextRank = this.maxRank;
                        this.previousRank = this.maxRank - 1;
                    }

                    // rank change callback
                    if (this.previousRank !== rank) {
                        this.config.onRankChange.call(
                            this,
                            rank,
                            this.nextRank,
                            previousRank,
                            add,
                            max,
                            rankUp
                        );
                    }
					
                    this.previousRank = rank;
                }

                requestAnimationFrame(animate);
            } else {		
                this.currentXP = targetXP;
				
                this.running = false;

                this.config.onEnd.call(this);
            }
        }

        animate();
    }
}

class XperienceUI {
    constructor(parent, options) {
        const defaultConfig = {
            parent: document.body,
            segments: 10,
            width: 532,
            theme: 'native',
            timeout: 5000
        };
        
        this.cfg = Object.assign({}, defaultConfig, options);
        this.cfg.parent = parent;
        this.displayTimer = false;
        this.build();
    }
    
    render() {
        this.cfg.parent.appendChild(this.nodes.main);
    }
    
    build() {
        const main = document.createElement('div');
        main.classList.add('xperience', `theme-${this.cfg.theme}`);
        
        const inner = document.createElement('div');
        inner.classList.add('xperience-inner');
        
        const data = document.createElement('div');
        data.classList.add('xperience-data');
        
        const rankA = document.createElement('div');
        rankA.classList.add('xperience-rank');
        
        const rankB = document.createElement('div');
        rankB.classList.add('xperience-rank');
        
        const progress = document.createElement('div');
        progress.classList.add('xperience-progress');
        
        const divA = document.createElement('div');
        const divB = document.createElement('div');
        
        const spanA = document.createElement('span');
        const spanB = document.createElement('span');
        
        main.appendChild(inner);
        main.appendChild(data);
        
        rankA.appendChild(divA);
        rankB.appendChild(divB);
        
        // if ( this.cfg.theme == 'native' ) {
            rankA.appendChild(this.createRankGlobe());
            rankB.appendChild(this.createRankGlobe());
        // }
        
        inner.appendChild(rankA);
        inner.appendChild(progress);
        inner.appendChild(rankB);
        
        data.appendChild(spanA);
        data.appendChild(spanB);
        
        this.nodes = {
            main, inner, data, rankA, rankB, progress
        };
        
        this.update();
    }
    
    open() {
        this.cfg.parent.classList.add("active");
        window.clearTimeout(this.displayTimer);
    }
    
    close() {
        this.cfg.parent.classList.remove("active");
        window.clearTimeout(this.displayTimer);
        this.displayTimer = false;
        
        PostData("ui_closed");
    }
    
    timeout() {
        this.open();

        this.displayTimer = window.setTimeout(() => {
            this.close();
        }, this.cfg.timeout);
    }

    
    fillSegments(progress, child) {
        const p = (ui.cfg.segments / 100) * progress;
        const filled = Math.floor(p);
        const partial = p % 1;

        for (let i = 0; i < ui.cfg.segments; i++) {
            if (i + 1 <= filled) {
                ui.nodes.progress.children[i][child].style.width = "100%";
            } else {
                ui.nodes.progress.children[i][child].style.width = "0%";
            }

            if (i + 1 === filled + 1) {
                ui.nodes.progress.children[i][child].style.width = `${partial * 100}%`;
            }
        }
    }
    
    createRankGlobe() {
        const ns = "http://www.w3.org/2000/svg";
        const svg = document.createElementNS(ns, "svg");
        svg.setAttributeNS(null, 'viewBox', '0 0 1104 1104');
        
        const g = document.createElementNS(ns, "g");
        
        const circle = document.createElementNS(ns, "circle");
        circle.setAttributeNS(null, 'cx', '552.13');
        circle.setAttributeNS(null, 'cy', '551.577');
        circle.setAttributeNS(null, 'r', '512');
        
        const lineA = document.createElementNS(ns, "line");
        lineA.setAttributeNS(null, 'x1', '66.298');
        lineA.setAttributeNS(null, 'y1', '713.576');
        lineA.setAttributeNS(null, 'x2', '1037.962');
        lineA.setAttributeNS(null, 'y2', '713.576');
        
        const lineB = document.createElementNS(ns, "line");
        lineB.setAttributeNS(null, 'x1', '1037.962');
        lineB.setAttributeNS(null, 'y1', '389.577');
        lineB.setAttributeNS(null, 'x2', '66.298');
        lineB.setAttributeNS(null, 'y2', '389.577');
        
        const pathA = document.createElementNS(ns, "path");
        pathA.setAttributeNS(null, 'd', 'M721.313,1034.963c50.182-119.717,81.658-291.957,81.658-483.386 c0-191.43-31.477-363.671-81.658-483.387');
        
        const pathB = document.createElementNS(ns, "path");
        pathB.setAttributeNS(null, 'd', 'M382.945,68.192c-50.181,119.716-81.656,291.957-81.656,483.384 c0,191.427,31.476,363.666,81.655,483.382');
        
        svg.appendChild(g);
        g.appendChild(circle);
        g.appendChild(lineA);
        g.appendChild(lineB);
        g.appendChild(pathA);
        g.appendChild(pathB);
        
        return svg;
    }
    
    setTheme(theme) {
        // Remove previous theme class
        this.nodes.main.classList.remove(`theme-${this.cfg.theme}`);

        // Set the new theme
        this.cfg.theme = theme.theme;

        // Add the new theme class
        this.nodes.main.classList.add(`theme-${this.cfg.theme}`);

        // Set the segment count
        this.cfg.segments = theme.segments;

        // Set the width
        this.cfg.width = theme.width;
        
        this.update();
    }
    
    update() {
        // Remove old segments
        while (this.nodes.progress.lastElementChild) {
            this.nodes.progress.removeChild(this.nodes.progress.lastElementChild);
        }
        
        // Add new segments
        const frag = document.createDocumentFragment();
        for (let i = 0; i < this.cfg.segments; i++) {
            const div = document.createElement("div");
            div.classList.add("xperience-segment");
            div.innerHTML = `<div class="xperience-indicator--bar"></div><div class="xperience-progress--bar"></div>`;

            frag.appendChild(div);
        }
        
        // Append the new segments
        this.nodes.progress.appendChild(frag);

        // Set the width
        this.nodes.inner.style.width = `${this.cfg.width}px`;
    }
}