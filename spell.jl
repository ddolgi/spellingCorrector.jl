#!/usr/local/bin/julia
import StatsBase: countmap

words(text) = collect(e.match for e in eachmatch(r"[a-z]+", lowercase(text)))

NWORDS = countmap(words(String(read(open("big.txt")))))

function candidates(word)
	(w = known([word])) != Set() || (w = known(edits1(word))) != Set() || (w = known(edits2(word))) != Set() || (w = [word])
	[ c for c in w ]
	# return w
end

function correct(word)
	cands = candidates(word)
	cands[argmax([ NWORDS[c] for c in cands ])]
end

alphabet = "abcdefghijklmnopqrstuvwxyz"
function edits1(word)
	s = [(word[1:i], word[i+1:end]) for i in 0:length(word)]
	deletes    = Set("$a$(b[2:end])" for (a, b) in s[1:end-1])
	transposes = Set("$a$(b[2])$(b[1])$(b[3:end])" for (a, b) in s[1:end-2])
	replaces   = Set("$a$c$(b[2:end])" for (a, b) in s[1:end-1], c in alphabet)
	inserts    = Set("$a$c$b" for (a, b) in s, c in alphabet)
	union(deletes, transposes, replaces, inserts)
end

edits2(word) = [e2 for e1 in edits1(word) for e2 in edits1(e1)]

known(words) = Set(w for w in words if haskey(NWORDS, w))


#################### TEST 
function spelltest(tests, bias=Union{}, verbose=false)
	n, bad, unknown = 0, 0, 0
#if bias:
#for target in tests: NWORDS[target] += bias
	for (target, wrongs) in tests
		for wrong in split(wrongs)
			n += 1
			w = correct(wrong)
			if w!=target
				bad += 1
				if !haskey(NWORDS, target)
					unknown += 1
				end
			end
		end
	end
	return Dict("bad"=>bad, "n"=>n, "bias"=>bias, "pct"=>floor(Int, 100.0 - 100.0*bad/n),
				"unknown"=>unknown)
end

@time println(correct("xtas"))
# using JSON
# @time println(spelltest(JSON.parse(open("test1.json","r"))))
# @time println(spelltest(JSON.parse(open("test2.json","r"))))
