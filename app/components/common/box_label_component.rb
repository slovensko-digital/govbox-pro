module Common
  class BoxLabelComponent < ViewComponent::Base
    def initialize(box)
      @box = box
    end
  end
end

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Necessary to generate proper CSS for dynamically generated colors
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# !!!!!!   Change values here, if values in template change  !!!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# class="bg-slate-100 border border-slate-400 text-slate-600"
# class="bg-gray-100 border border-gray-400 text-gray-600"
# class="bg-zinc-100 border border-zinc-400 text-zinc-600"
# class="bg-neutral-100 border border-neutral-400 text-neutral-600"
# class="bg-stone-100 border border-stone-400 text-stone-600"
# class="bg-red-100 border border-red-400 text-red-600"
# class="bg-orange-100 border border-orange-400 text-orange-600"
# class="bg-amber-100 border border-amber-400 text-amber-600"
# class="bg-yellow-100 border border-yellow-400 text-yellow-600"
# class="bg-lime-100 border border-lime-400 text-lime-600"
# class="bg-green-100 border border-green-400 text-green-600"
# class="bg-emerald-100 border border-emerald-400 text-emerald-600"
# class="bg-teal-100 border border-teal-400 text-teal-600"
# class="bg-cyan-100 border border-cyan-400 text-cyan-600"
# class="bg-sky-100 border border-sky-400 text-sky-600"
# class="bg-blue-100 border border-blue-400 text-blue-600"
# class="bg-indigo-100 border border-indigo-400 text-indigo-600"
# class="bg-violet-100 border border-violet-400 text-violet-600"
# class="bg-purple-100 border border-purple-400 text-purple-600"
# class="bg-fuchsia-100 border border-fuchsia-400 text-fuchsia-600"
# class="bg-pink-100 border border-pink-400 text-pink-600"
# class="bg-rose-100 border border-rose-400 text-rose-600"