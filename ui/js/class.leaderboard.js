class Leaderboard {
    constructor(options) {
        const config = {
            showPing: false,
            perPage: 18,
            sortBy: "rank"
        };

        this.config = Object.assign({}, config, options);

        this.container = document.getElementById("xperience_leaderboard");
        this.players = {};

        this.paginator = new Paginator(this.config.perPage, this.config.sortBy);

        this.init();
    }

    init() {
        this.inner = document.createElement("div");
        this.inner.classList.add("xperience-leaderboard--inner");

        this.header = document.createElement("div");
        this.header.classList.add("xperience-leaderboard--header");

        this.counter = document.createElement("div");
        this.counter.classList.add("xperience-leaderboard--counter");

        this.pager = document.createElement("div");
        this.pager.classList.add("xperience-leaderboard--pager");

        this.list = document.createElement("ul");
        this.list.classList.add("xperience-leaderboard--players");

        this.header.appendChild(this.counter);
        this.header.appendChild(this.pager);

        this.inner.appendChild(this.header);
        this.inner.appendChild(this.list);
    }

    render() {
        this.container.appendChild(this.inner);
        this.update();
    }

    addPlayer(player, update = false) {
        const li = document.createElement("li");
        li.classList.add("xperience-leaderboard--player");

        const info = document.createElement("div");
        info.classList.add("xperience-leaderboard--playerinfo");

        const name = document.createElement("div");
        name.classList.add("xperience-leaderboard--playername");

        const rank = document.createElement("div");
        rank.classList.add("xperience-leaderboard--playerrank");

        const num = document.createElement("div");
        num.classList.add("xperience-leaderboard--playerranknum");

        name.textContent = player.name;
        num.textContent = player.rank;

        const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        svg.innerHTML = `<g>
                            <circle cx="552.13" cy="551.577" r="512" />
                            <line x1="66.298" y1="713.576" x2="1037.962" y2="713.576" />
                            <line x1="1037.962" y1="389.577" x2="66.298" y2="389.577" />
                            <path d="M721.313,1034.963c50.182-119.717,81.658-291.957,81.658-483.386
        c0-191.43-31.477-363.671-81.658-483.387" />
                            <path d="M382.945,68.192c-50.181,119.716-81.656,291.957-81.656,483.384
        c0,191.427,31.476,363.666,81.655,483.382" />
                        </g>`;

        svg.setAttribute("viewBox", "0 0 1104 1104");

        rank.appendChild(svg);
        rank.appendChild(num);

        info.appendChild(name);

        if (this.config.showPing) {
            const ping = document.createElement("div");
            ping.classList.add("xperience-leaderboard--playerping");

            ping.textContent = `${player.ping}ms`;

            info.appendChild(ping);
        }

        li.appendChild(info);
        li.appendChild(rank);

        this.list.appendChild(li);

        player.row = li;

        this.players[player.id] = player;
        this.paginator.addItem(player);

        if (update) {
            this.paginator.setList(this.players);
            this.update();
        }

        this.counter.textContent = `Players: ${this.getPlayerCount()}`;
    }

    updatePlayers(players) {
        this.players = {};
        const count = Object.keys(players).length;

        let n = 1;
        for (const id in players) {
            this.addPlayer(players[id], n == count);
            n++
        }

        this.update();
    }

    update(order) {
        if (order === undefined) {
            order = this.config.sortBy;
        }

        this.paginator.setList(this.players);
        this.paginator.paginate(order);

        this.list.innerHTML = "";

        if (this.paginator.pages.length) {
            for (const player of this.paginator.getCurrentPage()) {
                this.list.appendChild(this.players[player.id].row);
            }
        }

        this.counter.textContent = `Players: ${this.getPlayerCount()}`;
        this.pager.textContent =
            this.paginator.totalPages > 1 ?
            `${this.paginator.currentPage} / ${this.paginator.totalPages}` :
            "";
    }

    nextPage() {
        if (
            this.paginator.totalPages > 1 &&
            this.paginator.currentPage < this.paginator.lastPage
        ) {
            this.paginator.currentPage++;

            this.update();
        }
    }

    prevPage() {
        if (this.paginator.totalPages > 1 && this.paginator.currentPage > 1) {
            this.paginator.currentPage--;

            this.update();
        }
    }

    setPage(page) {
        if (page >= 1 && page <= this.paginator.totalPages) {
            this.paginator.currentPage = page;

            this.update();
        }
    }

    getPlayerCount() {
        return Object.keys(this.players).length;
    }

    addPlayers(players) {
        for (const player of players) {
            if (!(player.id in this.players)) {
                this.addPlayer(player);
            }
        }

        this.update();
    }

    removePlayer(player, update = false) {
        // Switch to first page to prevent errors
        if (this.paginator.currentPage > 1) {
            this.setPage(1);
        }

        if (player.id in this.players) {
            if (this.list.contains(this.players[player.id].row)) {
                this.list.removeChild(this.players[player.id].row);
            }

            delete this.players[player.id];

            if (update) {
                this.update();
            }
        }
    }

    removePlayers(players) {
        for (const id in players) {
            this.removePlayer(players[id]);
        }

        this.update();
    }

    updateRank(id, rank) {
        if (id in this.players) {
            this.players[id].rank = rank;
            this.players[id].row.querySelector(
                ".xperience-leaderboard--playerranknum"
            ).textContent = rank;
        }
    }
}