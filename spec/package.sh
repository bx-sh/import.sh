name import-specs

script test     bx multi-bash build-and-run 3.2,latest ./packages/bin/spec
script test-3.2 bx multi-bash build-and-run 3.2        ./packages/bin/spec

dependency bx
dependency BxSH
dependency @multi-bash
dependency @spec
dependency @assert
dependency @expect