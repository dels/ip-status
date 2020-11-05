class Numeric
    def duration
        steps=[60, 60, 24, 365,0]
        names=[:seconds, :minutes, :hours, :days, :years]
        results=[]
        stepper = self.to_int.abs
        steps.each { |div|
            if stepper>0
                if div>0
                    results<<stepper % div
                    stepper/=div
                else
                    results << stepper
                end
            end
        }
        e= results.empty? ? 0 : results.count-1
        mt= e>0 ? results[e-1] : 0
        et=results[e] || 0

        et.to_s+" "+names[e].to_s + (mt>0 ? " "+mt.to_s+" "+names[e-1].to_s : '')
    end
end
