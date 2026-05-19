{ inputs, ... }:

{
    imports = [ inputs.nixvim.homeModules.nixvim ];

    programs.nixvim = {
        enable = true;
        defaultEditor = true;
        vimAlias = true;

        globals.mapleader = " ";
        globals.maplocalleader = " ";

        opts = {
            # Display
            guicursor = "";
            number = true;
            relativenumber = true;
            wrap = false;
            scrolloff = 10;
            showmode = false;
            showtabline = 2;
            cursorline = true;
            signcolumn = "yes";
            list = true;
            listchars = {
                tab = "» ";
                trail = "·";
                nbsp = "␣";
            };

            # Indent
            tabstop = 4;
            softtabstop = 4;
            shiftwidth = 4;
            expandtab = true;
            smartindent = true;
            breakindent = true;

            # Search
            incsearch = true;
            ignorecase = true;
            smartcase = true;
            inccommand = "split";

            # Behavior
            mouse = "a";
            clipboard = "unnamedplus";
            undofile = true;
            timeoutlen = 300;
            splitright = true;
            splitbelow = true;
            confirm = true;
        };

        # Diagnostic config (matches kickstart init.lua)
        extraConfigLua = ''
            vim.diagnostic.config({
                update_in_insert = false,
                severity_sort = true,
                float = { border = 'rounded', source = 'if_many' },
                underline = { severity = { min = vim.diagnostic.severity.ERROR } },
                virtual_text = { severity = { min = vim.diagnostic.severity.ERROR } },
                virtual_lines = false,
                jump = { float = true },
            })
        '';

        autoCmd = [
            {
                event = [ "TextYankPost" ];
                desc = "Highlight when yanking (copying) text";
                callback.__raw = ''
                    function()
                        vim.hl.on_yank()
                    end
                '';
            }
        ];

        keymaps = [
            # Clear search highlight
            { mode = "n"; key = "<Esc>"; action = "<cmd>nohlsearch<CR>"; }

            # Diagnostic loclist
            {
                mode = "n";
                key = "<leader>q";
                action.__raw = "vim.diagnostic.setloclist";
                options.desc = "Open diagnostic [Q]uickfix list";
            }

            # Exit terminal mode
            {
                mode = "t";
                key = "<Esc><Esc>";
                action = "<C-\\><C-n>";
                options.desc = "Exit terminal mode";
            }

            # Window focus (Ctrl+hjkl)
            { mode = "n"; key = "<C-h>"; action = "<C-w><C-h>"; options.desc = "Move focus to the left window"; }
            { mode = "n"; key = "<C-l>"; action = "<C-w><C-l>"; options.desc = "Move focus to the right window"; }
            { mode = "n"; key = "<C-j>"; action = "<C-w><C-j>"; options.desc = "Move focus to the lower window"; }
            { mode = "n"; key = "<C-k>"; action = "<C-w><C-k>"; options.desc = "Move focus to the upper window"; }

            # Cycle windows and tabs (Alt+arrows)
            { mode = "n"; key = "<M-Up>";    action = "<C-w>W";              options.desc = "Previous window"; }
            { mode = "n"; key = "<M-Down>";  action = "<C-w>w";              options.desc = "Next window"; }
            { mode = "n"; key = "<M-Left>";  action = "<cmd>tabprevious<CR>"; options.desc = "Previous tab"; }
            { mode = "n"; key = "<M-Right>"; action = "<cmd>tabnext<CR>";     options.desc = "Next tab"; }

            # Save / close
            { mode = "n"; key = "<leader>ss"; action = "<cmd>wall<CR>";          options.desc = "Write all"; }
            { mode = "n"; key = "<leader>n";  action = "<cmd>Neotree toggle<CR>"; options.desc = "Toggle Neo-tree"; }
            { mode = "n"; key = "<leader>³"; action = "<cmd>close<CR>";         options.desc = "Close window"; }
            { mode = "n"; key = "<leader>qq"; action = "<cmd>qa<CR>";            options.desc = "Quit all"; }

            # Format buffer (conform)
            {
                mode = [ "n" "v" ];
                key = "<leader>f";
                action.__raw = ''
                    function()
                        require('conform').format({ async = true, lsp_format = 'fallback' })
                    end
                '';
                options.desc = "[F]ormat buffer";
            }

            # Toggle inlay hints
            {
                mode = "n";
                key = "<leader>th";
                action.__raw = ''
                    function()
                        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }))
                    end
                '';
                options.desc = "[T]oggle Inlay [H]ints";
            }

            # Telescope variants requiring a lua function (the rest are in plugins.telescope.keymaps)
            {
                mode = "n";
                key = "<leader>/";
                action.__raw = ''
                    function()
                        require('telescope.builtin').current_buffer_fuzzy_find(
                            require('telescope.themes').get_dropdown({
                                winblend = 10,
                                previewer = false,
                            })
                        )
                    end
                '';
                options.desc = "[/] Fuzzily search in current buffer";
            }
            {
                mode = "n";
                key = "<leader>s/";
                action.__raw = ''
                    function()
                        require('telescope.builtin').live_grep({
                            grep_open_files = true,
                            prompt_title = 'Live Grep in Open Files',
                        })
                    end
                '';
                options.desc = "[S]earch [/] in Open Files";
            }
            {
                mode = "n";
                key = "<leader>sn";
                action.__raw = ''
                    function()
                        require('telescope.builtin').find_files({ cwd = vim.fn.stdpath('config') })
                    end
                '';
                options.desc = "[S]earch [N]eovim files";
            }
        ];

        plugins = {
            # Indent detection
            guess-indent.enable = true;

            # Required by telescope, neo-tree, etc.
            web-devicons.enable = true;

            # Statusline
            lualine.enable = true;

            # Highlighting
            treesitter = {
                enable = true;
                settings.indent.enable = true;
            };

            # Git signs in gutter
            gitgutter.enable = true;

            # Pending keybinds popup
            which-key = {
                enable = true;
                settings = {
                    delay = 0;
                    spec = [
                        { __unkeyed-1 = "<leader>s"; group = "[S]earch"; mode = [ "n" "v" ]; }
                        { __unkeyed-1 = "<leader>t"; group = "[T]oggle"; }
                        { __unkeyed-1 = "<leader>h"; group = "Git [H]unk"; mode = [ "n" "v" ]; }
                        { __unkeyed-1 = "gr"; group = "LSP Actions"; mode = "n"; }
                    ];
                };
            };

            # Highlight TODO/NOTE/FIXME comments
            todo-comments = {
                enable = true;
                settings.signs = false;
            };

            # mini.ai (textobjects) + mini.surround (add/delete/replace surroundings)
            mini = {
                enable = true;
                modules = {
                    ai = { n_lines = 500; };
                    surround = { };
                };
            };

            # Formatter
            conform-nvim = {
                enable = true;
                settings = {
                    notify_on_error = false;
                    formatters_by_ft = {
                        lua = [ "stylua" ];
                    };
                };
            };

            # File tree (replaces kickstart's kickstart.plugins.neo-tree)
            neo-tree.enable = true;

            # LSP progress UI
            fidget.enable = true;

            # Fuzzy finder
            telescope = {
                enable = true;
                extensions = {
                    fzf-native.enable = true;
                    ui-select = {
                        enable = true;
                        settings.__raw = "require('telescope.themes').get_dropdown()";
                    };
                };
                keymaps = {
                    "<leader>sh"        = { action = "help_tags";   options.desc = "[S]earch [H]elp"; };
                    "<leader>sk"        = { action = "keymaps";     options.desc = "[S]earch [K]eymaps"; };
                    "<leader>sf"        = { action = "find_files";  options.desc = "[S]earch [F]iles"; };
                    "<leader>sw"        = { action = "grep_string"; options.desc = "[S]earch current [W]ord"; };
                    "<leader>sg"        = { action = "live_grep";   options.desc = "[S]earch by [G]rep"; };
                    "<leader>sd"        = { action = "diagnostics"; options.desc = "[S]earch [D]iagnostics"; };
                    "<leader>sr"        = { action = "resume";      options.desc = "[S]earch [R]esume"; };
                    "<leader>s."        = { action = "oldfiles";    options.desc = "[S]earch Recent Files"; };
                    "<leader>sc"        = { action = "commands";    options.desc = "[S]earch [C]ommands"; };
                    "<leader><leader>"  = { action = "buffers";     options.desc = "Find existing buffers"; };
                    # Telescope LSP variants (kickstart's LspAttach overrides)
                    "grr" = { action = "lsp_references";                options.desc = "[G]oto [R]eferences (telescope)"; };
                    "gri" = { action = "lsp_implementations";           options.desc = "[G]oto [I]mplementation (telescope)"; };
                    "grd" = { action = "lsp_definitions";               options.desc = "[G]oto [D]efinition (telescope)"; };
                    "grt" = { action = "lsp_type_definitions";          options.desc = "[G]oto [T]ype Definition (telescope)"; };
                    "gO"  = { action = "lsp_document_symbols";          options.desc = "Open Document Symbols"; };
                    "gW"  = { action = "lsp_dynamic_workspace_symbols"; options.desc = "Open Workspace Symbols"; };
                };
            };

            lsp = {
                enable = true;
                servers = {
                    dockerls.enable = true;
                    bashls.enable = true;
                    nixd.enable = true; # Nix
                    pyright.enable = true; # Python
                    ruff.enable = true; # Python
                    #sqls.enable = true; # SQL
                    sqruff.enable = true; # SQL
                    rust_analyzer = {
                        enable = true;
                        installCargo = false;
                        installRustc = false;
                    };
                    ts_ls.enable = true; # Javascript/Typescript
                    vue_ls.enable = true;
                    # Added from kickstart init.lua
                    lua_ls.enable = true;
                    terraformls.enable = true;
                    html.enable = true;
                };
                keymaps = {
                    diagnostic = {
                        "<leader><Right>" = "goto_next";
                        "<leader><Left>" = "goto_prev";
                    };
                    # LSP keymaps replaced with kickstart's mapping
                    lspBuf = {
                        "gd"  = "definition";
                        "gD"  = "definition";
                        "gr"  = "references";
                        "gi"  = "implementation";
                        "grn" = "rename";
                        "gra" = "code_action";
                        "grD" = "declaration";
                    };
                };
            };

            # Completion
            cmp = {
                enable = true;
                autoEnableSources = true;
                settings.sources = [
                    { name = "nvim_lsp"; }
                    { name = "path"; }
                    { name = "buffer"; }
                ];
                settings.mapping = { # From MikaelFangel's nixvim config
                    "<C-n>" = "cmp.mapping.select_next_item()";
                    "<C-p>" = "cmp.mapping.select_prev_item()";
                    "<C-j>" = "cmp.mapping.select_next_item()";
                    "<C-k>" = "cmp.mapping.select_prev_item()";
                    "<C-d>" = "cmp.mapping.scroll_docs(-4)";
                    "<C-f>" = "cmp.mapping.scroll_docs(4)";
                    "<C-Space>" = "cmp.mapping.complete()";
                    "<S-Tab>" = "cmp.mapping.close()";
                    "<CR>" =
                    # lua
                    ''
                      function(fallback)
                        local line = vim.api.nvim_get_current_line()
                        if line:match("^%s*$") then
                          fallback()
                        elseif cmp.visible() then
                          cmp.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true })
                        else
                          fallback()
                        end
                      end
                    '';
                    "<Down>" =
                    # lua
                    ''
                      function(fallback)
                        if cmp.visible() then
                          cmp.select_next_item()
                        else
                          fallback()
                        end
                      end
                    '';
                    "<Up>" =
                    # lua
                    ''
                      function(fallback)
                        if cmp.visible() then
                          cmp.select_prev_item()
                        else
                          fallback()
                        end
                      end
                    '';
                };
            };
        };
    };
}
