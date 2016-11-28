" write the parameters for a given function

"au FileType python set foldmethod=indent
setlocal omnifunc=pythoncomplete#Complete
setlocal completeopt=longest,menuone
setlocal completeopt-=preview
setlocal nosmartindent
setlocal makeprg=pylint-2.6\ --reports=n\ --output-format=parseable\ %:p
setlocal errorformat=%f:%l:\ %m
setlocal define=^\s*\\(def\\\\|class\\)


let g:flake8_ignore = "W801,E128,W806"
au BufWritePost <buffer> call Flake8()

" map <leader>r to run nosetests on the current file in another tmux pane
" TODO: replace this with alternate file plugin from tpope
nnoremap <buffer> <localleader>te :execute "vertical rightb split " . GetPathToTestFile()<cr>

" test function for running the file
function! s:GetPathToTestFile()
    let test_prefix = "test_"
    let current_dir = getcwd()
    let test_path = current_dir . "/Tests/" . expand("%:h") . "/test_" . expand("%:t")
    return test_path
endf

function! s:RunTest()
    let module_path = substitute(expand("%"), getcwd(), "", "g")
    let module_path = substitute(module_path, "/", ".", "g")
    let module_path = substitute(module_path, ".py", "", "g")
    let nose_command = "!nosetests --with-coverage --cover-erase --cover-package=" . module_path . " "

    let test_prefix = "test_"
    let filename = expand("%:t")
    let filename_prefix = strpart(filename, 0,5)
    if filename_prefix == test_prefix
        return nose_command . expand("%")
    endif
    let test_file_path = GetPathToTestFile()
    return nose_command . test_file_path
endf

function! s:WriteParams()
python << endpython
import re
import vim

# get the function definition line
line = vim.eval("getline(line('.'))")
# get the number of spaces to add to the start of the line
num_spaces = 4 + len(line) - len(line.lstrip())
# get the line number wher to do the insertion
line_number = int(vim.eval("line('.')"))

# find the parameter names in the function definition
params = re.findall("[\w=]+", line)[2:]

# the header and the footer of the doctstring
lines = ['"""', ""]

for param in params:
    # skip the 'self' since it doesn't have to be documented.
    if param == "self":
        continue
    # handle the default argument parameters
    if "=" in param:
        param_name = param.split('=')[0]
        param_default_value = "".join(param.split('=')[1:])
        lines.append(":param %s: (Default value: %s)" % (param_name, param_default_value))
        lines.append(":type %s:" % param_name)
    else:
        lines.append(":param %s:" % param)
        lines.append(":type %s:" % param)

lines.append(":returns:")
lines.append('"""')
# insert the contents of the list into the buffer
vim.current.buffer[:] = vim.current.buffer[:line_number] + [(" "*num_spaces)+line for line in lines] + vim.current.buffer[line_number:] 
endpython
endfunction

" convert json date to python datetime
function! s:ConvertJsonDate()
python << EOF
def _convert_json_date():
    import vim
    from datetime import datetime
    json_date = int(vim.eval("expand(\"<cword>\")"))
    return datetime.fromtimestamp(json_date / 1000.0)
print _convert_json_date()
EOF
endfunction

nmap \fd :call ConvertJsonDate()<cr>
nnoremap <buffer> <localleader>wp :call WriteParams()<cr>
nnoremap <buffer> <localleader>t :execute RunTest()<cr>
