#!/usr/local/bin/julia
import StatsBase: countmap

words(text) = collect(e.match for e in eachmatch(r"[a-z]+", lowercase(text)))

WORDS = countmap(words(String(read(open("big.txt")))))
N = sum(values(WORDS))
P(word) = get(WORDS, word, 0) / N

function candidates(word)
	(w = known([word])) != [] && return w
	(w = known(edits1(word))) != [] && return w
	(w = known(edits2(word))) != [] && return w
	return [word]
end

function correct(word)
	cands = candidates(word)
	return cands[argmax(map(P, cands))]
end

alphabet = "abcdefghijklmnopqrstuvwxyz"
function edits1(word)
	s = [(word[1:i], word[i+1:end]) for i in 0:length(word)]
	deletes    = ["$a$(b[2:end])" for (a, b) in s[1:end-1]]
	transposes = ["$a$(b[2])$(b[1])$(b[3:end])" for (a, b) in s[1:end-2]]
	replaces   = ["$a$c$(b[2:end])" for (a, b) in s[1:end-1] for c in alphabet]
	inserts    = ["$a$c$b" for (a, b) in s for c in alphabet]
	return vcat(deletes, transposes, replaces, inserts)
end

edits2(word) = Set(e2 for e1 in edits1(word) for e2 in edits1(e1))

known(words) = [w for w in words if haskey(WORDS, w)]



#################### TEST 
function spelltest(tests, bias=Union{}, verbose=false)
	n, bad, unknown = 0, 0, 0
#if bias:
#for target in tests: WORDS[target] += bias
	for (target, wrongs) in tests
		for wrong in split(wrongs)
			n += 1
			w = correct(wrong)
			if w!=target
				bad += 1
				if !haskey(WORDS, target)
					unknown += 1
				end
			end
		end
	end
	return Dict("bad"=>bad, "n"=>n, "bias"=>bias, "pct"=>floor(Int, 100.0 - 100.0*bad/n),
				"unknown"=>unknown)
end

@time println(correct("xtas"))
using JSON
@time println(spelltest(JSON.parse(open("test1.json","r"))))
@time println(spelltest(JSON.parse(open("test2.json","r"))))
