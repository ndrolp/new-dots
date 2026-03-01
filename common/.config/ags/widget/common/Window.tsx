import Astal from "gi://Astal"

export interface CustomWindowProps {
  children: JSX.Element | Array<JSX.Element>
  namespace: string
  name: string
  exclusivity: Astal.Exclusivity
}

export default function CustomWindow({ children }: CustomWindowProps) {
  return <window></window>
}
