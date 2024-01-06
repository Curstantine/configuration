return {
    {
        "sainnhe/sonokai",
        lazy = true,
        config = function()
            vim.g.sonokai_style = "andromeda"
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "sonokai",
        },
    },
}
