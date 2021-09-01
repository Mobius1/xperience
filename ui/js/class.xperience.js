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