## BennuGD2 - Branch for GNU/Linux only - Unstable


Upstream: https://github.com/SplinterGU/bennugd2



### How to build:

1) Clone (lightweight):

```bash

$ git clone --single-branch --depth=1 https://github.com/daltomi/bennugd2.git

```

2) Compile submodules:

```bash

$ ./build.sh submodules

```

3) Compile BennuGD2:

```bash

$ ./build.sh (debug default)

-- or --

$ ./build.sh release


```

### Read the help

```bash

$ ./build.sh help

```


---

### Helper: bennugd.sh

Helper of `bgdc`, `bgdi`, `moddesc`and `gdb`.
The most useful way to use this script is: `bennugd file.prg`,
compile and run at the same time.

**Note:**

It must be edited before being used **or** export the following in
your configuration of your shell:

```bash

 export MY_BENNUGD_LIBS=/home/YOU/bennugd2/build/linux/bin
 export MY_BENNUGD_BINS=/home/YOU/bennugd2/build/linux/bin

 alias bennugd=~/bennugd2/bennugd.sh

```

**Example:**

```bash

$ bennugd file.prg               (compile and run)
$ bennugd -c file.prg            (compile only)
$ bennugd -c file.prg -o mygame  (compile with options)
$ bennugd -i mygame.dcb          (interpreter)
$ bennugd -g -c file.prg         (run gdb with bgdc)
$ bennugd -g -i mygame.dcb       (run gdb with bgdi)
$ bennugd -h                     (show help)

```

---

Copyright © 2021 Daniel T. Borelli <danieltborelli[at]gmail[dot]com>

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.

   2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

   3. This notice may not be removed or altered from any source
   distribution.
