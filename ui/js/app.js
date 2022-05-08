let initialised = false;
let ui = false;
let rankbar = false;

function TriggerRankChange(rank, prev, rankUp) {
    PostData("rankchange", {
        current: rank, previous: prev, rankUp: rankUp
    });
}

function PostData(type = "", data = {}) {
    const resourceName = GetParentResourceName();

    fetch(`https://${resourceName}/${type}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).then(resp => resp).catch(error => console.log(`${resourceName} FETCH ERROR! ${error.message}`));    
}

function checkTheme(theme) {
    if ( theme == 'native' ) {
        return;
    }
    const id = `theme_${theme}`;
    
    if ( document.getElementById(id) === null ) {
        const link = document.createElement('link');
        link.setAttribute('rel', 'stylesheet');
        link.setAttribute('href', `css/theme-${theme}.css`);
        link.setAttribute('type', 'text/css');
        link.id = id;
        document.head.appendChild(link);
    }
}

window.onData = function (data) {
    if (data.init && !initialised) {
        checkTheme(data.theme.theme);

        ui = new XperienceUI(document.getElementById("main"), data.theme);

        let ranks = [];

        for ( let i = 0; i < data.ranks.length; i++ ) {
            ranks[i+1] = data.ranks[i];
        }

        rankbar = new Xperience({
            xp: data.xp,
            ranks: ranks,

            // set initial XP / rank
            onInit: function (progress) {
                // create segmented progress bar
                ui.render();

                // fill to starting XP / rank
                ui.fillSegments(progress, "lastElementChild");

                // Update rank indicators
                ui.nodes.rankA.firstElementChild.textContent = this.currentRank;
                ui.nodes.rankB.firstElementChild.textContent = this.nextRank;

                // Update XP counter
                ui.nodes.data.children[0].textContent = this.currentXP;
                ui.nodes.data.children[1].textContent = this.config.ranks[this.nextRank];

                // add new ranks
                ui.nodes.rankA.classList.add(`xp-rank-${this.currentRank}`);
                ui.nodes.rankB.classList.add(`xp-rank-${this.nextRank}`);

                initialised = true;

                PostData("ui_initialised");
            },

            onStart: function (add) {
                ui.open();

                // make segments red if removing XP
                ui.nodes.progress.classList.toggle("xperience-remove", !add);
            },

            // Update XP progress
            onChange: function (progress, xp, max, add) {
                ui.nodes.main.classList.add("active");

                // update progress bar
                ui.fillSegments(progress, "lastElementChild");

                // update indicator bar
                ui.fillSegments(max, "firstElementChild");

                // update xp counter
                ui.nodes.data.children[0].textContent = xp;
            },

            // Update on rank change
            onRankChange: function (current, next, previous, add, max, rankUp) {
                // Fire rank change to update client UI
                TriggerRankChange(current, previous, rankUp);

                // Remove old ranks
                ui.nodes.rankA.classList.remove(`xp-rank-${previous}`);
                ui.nodes.rankB.classList.remove(`xp-rank-${current}`);
                ui.nodes.rankB.classList.remove(`xperience-rank-${previous + 1}`);

                // add new ranks
                ui.nodes.rankA.classList.add(`xp-rank-${current}`);
                ui.nodes.rankB.classList.add(`xp-rank-${next}`);

                ui.nodes.data.children[1].textContent = this.config.ranks[next];

                ui.fillSegments(0, "firstElementChild");
        
                if ( ui.cfg.theme == 'native' ) {
                    ui.nodes.rankB.classList.add("pulse");
            
                    window.setTimeout(() => {
                        ui.nodes.rankB.classList.remove("pulse");
                        ui.nodes.rankA.classList.add("spin");
                        ui.nodes.rankA.classList.add("highlight");
                        ui.nodes.rankB.classList.add("spin");

                        ui.nodes.rankA.firstElementChild.textContent = current;
                        ui.nodes.rankB.firstElementChild.textContent = next;

                        window.setTimeout(() => {
                            ui.nodes.rankA.classList.remove("spin");
                            ui.nodes.rankA.classList.remove("highlight");
                            ui.nodes.rankB.classList.remove("spin");
                            ui.nodes.rankB.classList.remove("highlight");
                        }, 250);
                    }, 250);
                } else {
                    ui.nodes.rankA.firstElementChild.textContent = current;
                    ui.nodes.rankB.firstElementChild.textContent = next;
                }
            },

            onEnd: function (add) {
                PostData("save", {
                    xp: this.currentXP,
                    rank: this.currentRank
                });

                // hide the xp bar
                ui.timeout();

                ui.nodes.progress.classList.remove("xperience-remove");
            }
        });
    }
 
    if (data.event && initialised) {
        switch(data.event) {
            case 'theme':
                checkTheme(data.theme.theme);
                ui.setTheme(data.theme);
                ui.fillSegments(rankbar.rankProgress, "lastElementChild");
                break;
            case 'show':
                ui.timeout();
                break;
            case 'hide':
                ui.close();
                break;
            case 'set':
                rankbar.setXP(data.xp);
                break;  
            case 'add':
                rankbar.addXP(data.xp);
                break;  
            case 'remove':
                rankbar.removeXP(data.xp);
                break;                                                                                             
        }
    }  
};

window.onload = function (e) {
    window.addEventListener('message', function (e) {
        onData(e.data);
    });
};