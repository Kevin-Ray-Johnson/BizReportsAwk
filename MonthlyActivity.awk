#!/usr/bin/gawk -f

function repeatStrNtimes (Str, n) {
    retStr = ""
    for(i=0 ; i<n; i++ ) { retStr = retStr Str }
    return retStr
}

function spaces (n) { return repeatStrNtimes(" ", n) }

function getDate (dateStr, formatStr) {
    cmd = "date " dateStr " +\"" formatStr "\""
    if ((cmd | getline returnDate) <= 0) {
        print "Can't get system date" > "/dev/stderr"
        exit 1
    }
    else {
        close(cmd)
        return returnDate
    }
}

BEGIN{
    FS = ","
    PATH = ENVIRON["HOME"] "/Documents/"
    ODSFILE = PATH "KevinJohnsonAviation_Business-Log.ods"
    if (1 - system( "unoconv -f csv " ODSFILE)) {
        ARGV[1] = PATH "KevinJohnsonAviation_Business-Log.csv"
        ARGC = 2
        getline # Loose the column header row.
        date_now = getDate("", "%e %b. %Y")
        startDateVal = 9**9**9  # approx. infinity
        lastDateVal = -startDateVal
        split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", month, " ")
        for (i=1; i<=12; i++) {
            mSales[month[i]] = 0
            mExpen[month[i]] = 0
        }
    }
    else {
        print "ERROR converting ODF to CSV using unoconv"
        exit 1
    }
}

{
    date = $1
    customer = $2
    invoiced = $3
    paid = $4
    balance = $5
    supplier = $6
    expense = $7

    dateVal = getDate( "-d \"" date "\"", "%Y%j")
    if (dateVal > lastDateVal) {
        lastDateVal = dateVal
        lastDate = date
    }
    if (dateVal < startDateVal) {
        startDateVal = dateVal
        startDate = date
    }

    invoicedValue = gensub("[,$\"]", "", "g", invoiced)
    if ((customer != "") && (invoicedValue > 0)) {
        SalesToCustomers[customer] = SalesToCustomers[customer] + invoicedValue
        owesOnThisInvoice = gensub("[,$\"]", "", "g", balance)
        if (owesOnThisInvoice < 0) {
            OwesMe[customer] = OwesMe[customer] - owesOnThisInvoice
        }
    }

    expenseValue = gensub("[,$\"]", "", "g", expense)
    if ((supplier != "") && (expenseValue < 0)) {
        ExpensesByVendor[supplier] = ExpensesByVendor[supplier] + expenseValue
    }

    for (i=1; i<=12; i++) {
        if (match(date, month[i])) {
            mSales[month[i]] = mSales[month[i]] + invoicedValue
            mExpen[month[i]] = mExpen[month[i]] + expenseValue
            break
        }
    }
}

END {
    print "MONTHLY SALES/EXPENSES:"
    print "Generated on " date_now
    print "Data from " startDate " to " lastDate "\n"
    q = spaces(4)
    strFormat = "%s%s%s%10'.2f%s%10'.2f%s%10'.2f\n"
    printf("%s%s%s%10s%s%10s%s%10s\n", q, "MONTH", q, "SALES", q, "EXPENSES", q, "NET")
    for (i=1; i<=12; i++) {
        printf(strFormat, q, month[i] "  ", q, mSales[month[i]], \
                                            q, mExpen[month[i]], \
                                            q, mSales[month[i]] + mExpen[month[i]])
    }
    print ""
}
